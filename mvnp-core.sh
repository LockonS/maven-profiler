#!/usr/bin/env bash
# shellcheck shell=bash
#
# mvnp-core.sh - shared maven-profiler core logic.
#
# This file is written to be compatible with both bash and zsh, so it can
# be sourced from either:
#   - maven-profiler.plugin.zsh, processed by zsh, used as an oh-my-zsh plugin
#   - maven-profiler.entry.sh,   processed by bash, used standalone (no oh-my-zsh)
#
# It only defines variables/functions when sourced; it does not execute
# anything on its own and should not be run directly.
#
# Sourcing this file (e.g. into an interactive oh-my-zsh session) inevitably
# makes every top-level function here directly callable from the CLI - shells
# have no concept of "private" functions. To keep that surface small, all
# implementation details are funneled through the single `_mvnp_internal`
# dispatcher below; only `mvn-profiler`, `_mvnp_switch_profile` and
# `_mvnp_show_profile` are meant to be used directly (the latter two only via
# the `mvnp-switch`/`mvnp-show` aliases).

MAVEN_PROFILER_PROMPT_TITLE='MAVEN'
MAVEN_PROFILER_DEFAULT_PROFILE='default'
MAVEN_PROFILER_CUSTOM_ENV_FILE=".mvn-profile"

# namespaced colors, only enabled when stdout is an actual terminal - keeps
# piped/redirected output (e.g. `mvnp test > build.log`) free of escape codes
if [[ -t 1 ]]; then
  MVNP_COLOR_RED='\033[0;31m'
  MVNP_COLOR_GREEN='\033[0;32m'
  MVNP_COLOR_BIBLUE='\033[1;94m'
  MVNP_COLOR_BIWHITE='\033[1;97m'
  MVNP_COLOR_RESET='\033[0m'
else
  MVNP_COLOR_RED=''
  MVNP_COLOR_GREEN=''
  MVNP_COLOR_BIBLUE=''
  MVNP_COLOR_BIWHITE=''
  MVNP_COLOR_RESET=''
fi

if [[ -n "$MAVEN_PROFILE" ]]; then
  # clear MAVEN_PROFILE at the loading phase
  # if MAVEN_PROFILE is not cleared in this phase, then MAVEN_PROFILE config could only be reset after re-login
  export MAVEN_PROFILE=''
fi

# internal dispatcher - not meant to be called directly. Bundles every
# implementation-detail helper behind a single subcommand-style entry point
# instead of leaving each one as its own separately-named global function.
_mvnp_internal() {
  local ACTION=$1
  shift

  case "$ACTION" in
    error)
      printf '%b\n' "[${MVNP_COLOR_BIBLUE}${MAVEN_PROFILER_PROMPT_TITLE}${MVNP_COLOR_RESET}] ${MVNP_COLOR_BIWHITE}---${MVNP_COLOR_RESET} ${MVNP_COLOR_RED}${1}${MVNP_COLOR_RESET} ${MVNP_COLOR_BIWHITE} ---${MVNP_COLOR_RESET}"
      ;;

    prompt)
      printf '%b\n' "[${MVNP_COLOR_BIBLUE}${MAVEN_PROFILER_PROMPT_TITLE}${MVNP_COLOR_RESET}] ${MVNP_COLOR_BIWHITE}---${MVNP_COLOR_RESET} ${MVNP_COLOR_GREEN}${1}${MVNP_COLOR_RESET} ${MVNP_COLOR_BIWHITE}(${2}) ---${MVNP_COLOR_RESET}"
      ;;

    assemble-config-path)
      local TARGET_MAVEN_PROFILE=${1}
      # use default conf file for profile 'default'
      if [[ "$TARGET_MAVEN_PROFILE" == "$MAVEN_PROFILER_DEFAULT_PROFILE" ]]; then
        echo "$MAVEN_HOME/conf/settings.xml"
      else
        echo "$MAVEN_HOME/conf/settings-$TARGET_MAVEN_PROFILE.xml"
      fi
      ;;

    fallback-default-profile)
      # validations
      if [[ -z $MAVEN_PROFILE ]]; then
        # apply default maven profile
        export MAVEN_PROFILE=$MAVEN_PROFILER_DEFAULT_PROFILE
      fi
      ;;

    env-conf-lookup)
      local CURRENT_DIR="$PWD"
      local CUSTOM_ENV_FILE=""
      local CUSTOM_ENV_FILE_LINE
      local TARGET_MAVEN_PROFILE

      # walk up from current directory to / looking for the first readable custom env file
      # (uses `dirname` instead of zsh's `:h` modifier, so it works under bash too)
      while [[ -n "$CURRENT_DIR" ]]; do
        if [[ -r "$CURRENT_DIR/$MAVEN_PROFILER_CUSTOM_ENV_FILE" ]]; then
          _mvnp_internal prompt "env config" "$CURRENT_DIR/$MAVEN_PROFILER_CUSTOM_ENV_FILE"
          CUSTOM_ENV_FILE="$CURRENT_DIR/$MAVEN_PROFILER_CUSTOM_ENV_FILE"
          break
        fi
        if [[ "$CURRENT_DIR" == "/" ]]; then
          break
        fi
        CURRENT_DIR="$(dirname "$CURRENT_DIR")"
      done

      if [[ -z "$CUSTOM_ENV_FILE" ]]; then
        return 0
      fi

      # grab the first MAVEN_PROFILE assignment, then strip comment/quotes/whitespace
      CUSTOM_ENV_FILE_LINE=$(grep -m1 -E '^[[:space:]]*(export[[:space:]]+)?MAVEN_PROFILE[[:space:]]*=' "$CUSTOM_ENV_FILE")
      if [[ -z "$CUSTOM_ENV_FILE_LINE" ]]; then
        return 0
      fi

      TARGET_MAVEN_PROFILE=$(echo "${CUSTOM_ENV_FILE_LINE#*=}" | sed -E 's/#.*//' | tr -d '"'"'"'' | xargs)

      if [[ -n "$TARGET_MAVEN_PROFILE" ]]; then
        export MAVEN_PROFILE="$TARGET_MAVEN_PROFILE"
      fi
      ;;

    *)
      echo "[maven-profiler] internal error: unknown action '${ACTION}'" >&2
      return 1
      ;;
  esac
}

_mvnp_show_profile() {
  if [[ -n $MAVEN_PROFILE ]]; then
    _mvnp_internal prompt "mvn profile" "${MAVEN_PROFILE}"
  else
    _mvnp_internal prompt "mvn profile" "${MAVEN_PROFILER_DEFAULT_PROFILE}"
  fi
}

_mvnp_switch_profile() {
  local TARGET_MAVEN_PROFILE=${1}
  local TARGET_MAVEN_CONFIG_FILE
  # validate if maven config file exist
  TARGET_MAVEN_CONFIG_FILE=$(_mvnp_internal assemble-config-path "$TARGET_MAVEN_PROFILE")
  if [[ ! -f "$TARGET_MAVEN_CONFIG_FILE" ]]; then
    _mvnp_internal error "maven config file [$(basename "$TARGET_MAVEN_CONFIG_FILE")] not found, rollback to previous profile"
    _mvnp_show_profile
    return 1
  fi
  export MAVEN_PROFILE=$TARGET_MAVEN_PROFILE
  _mvnp_show_profile
}

mvn-profiler() {
  local JDK_VERSION_LINE MAVEN_EXECUTABLE

  # load environment variables from custom env file if exists
  _mvnp_internal env-conf-lookup

  # fallback to use default profile if no override settings found
  _mvnp_internal fallback-default-profile

  MAVEN_EXECUTABLE="$MAVEN_HOME/bin/mvn"
  MAVEN_CONFIG_FILE=$(_mvnp_internal assemble-config-path "$MAVEN_PROFILE")

  if [[ ! -f "$MAVEN_CONFIG_FILE" ]]; then
    _mvnp_internal error "maven config file [$(basename "$MAVEN_CONFIG_FILE")] not found"
    return 1
  fi

  if [[ ! -f "$MAVEN_EXECUTABLE" ]]; then
    _mvnp_internal error "maven executable not found, please check if \$MAVEN_HOME variable is properly configured"
    return 1
  fi

  # capture only the first line of `java --version`; avoids relying on
  # shell arrays, whose indexing differs between bash (0-based) and zsh (1-based)
  JDK_VERSION_LINE=$(java --version 2>&1 | head -n1)
  _mvnp_internal prompt "mvn profile" "${MAVEN_PROFILE}"
  _mvnp_internal prompt "mvn file" "${MAVEN_EXECUTABLE}"
  _mvnp_internal prompt "mvn setting" "${MAVEN_CONFIG_FILE}"
  _mvnp_internal prompt "jdk version" "${JDK_VERSION_LINE}"

  # pause for a short time for human eye to catch up with the prompt message
  sleep 1

  # execute mvn with designate config file and passed options
  # only override user settings (-s), mirroring how IntelliJ IDEA's Maven
  # integration works (it only exposes a "User settings file" option and
  # always relies on Maven's default global settings.xml)
  "$MAVEN_EXECUTABLE" -s "$MAVEN_CONFIG_FILE" "$@"
}


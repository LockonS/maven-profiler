#!/usr/bin/env zsh

_mvnp_load_env() {
  Red='\033[0;31m'
  Green='\033[0;32m'
  BIBlue='\033[1;94m'
  BIWhite='\033[1;97m'
  NC='\033[0m'

  MAVEN_PROFILER_PROMPT_TITLE='MAVEN'
  MAVEN_PROFILER_DEFAULT_PROFILE='default'

  if [[ -z "$MAVEN_PROFILE" ]]; then
    # MAVEN_PROFILE_DEFAULT_OVERRIDE might not be loaded into shell at the loading period
    export MAVEN_PROFILE=$MAVEN_PROFILE_DEFAULT_OVERRIDE
  else
    export MAVEN_PROFILE=''
  fi

  _mvnp_error() {
    echo -e "[${BIBlue}${MAVEN_PROFILER_PROMPT_TITLE}${NC}] ${BIWhite}---${NC} ${Red}${1}${NC} ${BIWhite} ---${NC}"
  }

  _mvnp_prompt() {
    echo -e "[${BIBlue}${MAVEN_PROFILER_PROMPT_TITLE}${NC}] ${BIWhite}---${NC} ${Green}${1}${NC} ${BIWhite}(${2}) ---${NC}"
  }

  _mvnp_show_profile() {
    if [[ -n $MAVEN_PROFILE ]]; then
      _mvnp_prompt "mvn profile" "${MAVEN_PROFILE}"
    else
      _mvnp_prompt "mvn profile" "${MAVEN_PROFILER_DEFAULT_PROFILE}"
    fi
  }

  _mvnp_switch_profile() {
    local TARGET_MAVEN_PROFILE=${1}
    local TARGET_MAVEN_CONFIG_FILE
    # validate if maven config file exist
    TARGET_MAVEN_CONFIG_FILE=$(_mvnp_assemble_config_file_path "$TARGET_MAVEN_PROFILE")
    if [[ ! -f "$TARGET_MAVEN_CONFIG_FILE" ]]; then
      _mvnp_error "maven config file [$(basename "$TARGET_MAVEN_CONFIG_FILE")] not found, rollback to previous profile"
      _mvnp_show_profile
      return 1
    fi
    export MAVEN_PROFILE=$TARGET_MAVEN_PROFILE
    _mvnp_show_profile
  }

  _mvnp_assemble_config_file_path() {
    local MAVEN_PROFILE=${1}
    # use default conf file for profile 'default'
    if [[ "$MAVEN_PROFILE" == "$MAVEN_PROFILER_DEFAULT_PROFILE" ]]; then
      MAVEN_CONFIG_FILE=$MAVEN_HOME/conf/settings.xml
    else
      MAVEN_CONFIG_FILE=$MAVEN_HOME/conf/settings-$MAVEN_PROFILE.xml
    fi
    echo "$MAVEN_CONFIG_FILE"
  }

  _mvnp_autoconfig() {
    # locate mvn installed on system if MAVEN_HOME is not set
    if [[ -n $MAVEN_HOME ]]; then
      echo -e "[maven-profiler] MAVEN_HOME is not empty, abort duplicated setup action"
      return 0
    fi
    if command -v mvn &>/dev/null; then
      MAVEN_EXECUTABLE=$(which mvn)
      export MAVEN_HOME="${MP_MAVEN_EXECUTABLE%/*/*}"
    else
      echo -e "[maven-profiler] maven is not found in PATH"
      return 1
    fi
  }

  mvn-profiler() {
    local JDK_VERSION_OUTPUT MAVEN_EXECUTABLE
    MAVEN_EXECUTABLE=$MAVEN_HOME/bin/mvn
    MAVEN_CONFIG_FILE=$MAVEN_HOME/conf/settings-$MAVEN_PROFILE.xml

    # validations
    if [[ -z $MAVEN_PROFILE ]]; then
      if [[ -n $MAVEN_PROFILE_DEFAULT_OVERRIDE ]]; then
        # if default maven profile is overrided, apply $MAVEN_PROFILE_DEFAULT_OVERRIDE automatically
        export MAVEN_PROFILE=$MAVEN_PROFILE_DEFAULT_OVERRIDE
      else
        # apply default maven profile
        export MAVEN_PROFILE=$MAVEN_PROFILER_DEFAULT_PROFILE
      fi
    fi

    MAVEN_CONFIG_FILE=$(_mvnp_assemble_config_file_path "$MAVEN_PROFILE")

    if [[ ! -f $MAVEN_CONFIG_FILE ]]; then
      _mvnp_error "maven config file [$(basename "$MAVEN_CONFIG_FILE")] not found"
      return 1
    fi

    if [[ ! -f $MAVEN_EXECUTABLE ]]; then
      _mvnp_error "maven executable not found, please check if \$MAVEN_HOME variable is properly configured"
      return 1
    fi

    # shellcheck disable=SC2207
    IFS=$'\n' JDK_VERSION_OUTPUT=($(java --version))
    _mvnp_prompt "jdk version" "${JDK_VERSION_OUTPUT[1]}"
    _mvnp_prompt "mvn profile" "${MAVEN_PROFILE}"
    _mvnp_prompt "mvn home" "${MAVEN_HOME}"
    _mvnp_prompt "mvn conf" "${MAVEN_CONFIG_FILE}"

    # pause for a short time for human eye to catch up with the prompt message
    sleep 1

    # execute mvn with designate config file and passed options
    "$MAVEN_EXECUTABLE" -s "$MAVEN_CONFIG_FILE" "$@"
  }

  # override default mvn command
  alias mvn=mvn-profiler
  alias mvnp=mvn-profiler
  alias mvnp-switch=_mvnp_switch_profile
}

_mvnp_load_env
unfunction _mvnp_load_env


#!/usr/bin/env zsh

_maven_profiler_load_env() {
  Red='\033[0;31m'
  Green='\033[0;32m'
  BIBlue='\033[1;94m'
  BIWhite='\033[1;97m'
  NC='\033[0m'

  MAVEN_PROFILER_PROMPT_TITLE='MAVEN'

  if [[ -z "$MAVEN_PROFILE" ]]; then
    export MAVEN_PROFILE=$MAVEN_PROFILE_DEFAULT_OVERRIDE
  else
    export MAVEN_PROFILE=''
  fi

  # override default mvn command
  alias mvnp=mvn-profiler
  alias mvn=mvn-profiler
}

_maven_profiler_error() {
  echo -e "[${BIBlue}${MAVEN_PROFILER_PROMPT_TITLE}${NC}] ${BIWhite}---${NC} ${Red}${1}${NC} ${BIWhite} ---${NC}"
}

_maven_profiler_prompt() {
  echo -e "[${BIBlue}${MAVEN_PROFILER_PROMPT_TITLE}${NC}] ${BIWhite}---${NC} ${Green}${1}${NC} ${BIWhite}(${2}) ---${NC}"
}

mvn-profiler() {
  local JDK_VERSION_OUTPUT MAVEN_EXECUTABLE MAVEN_CONFIG_FILE
  MAVEN_EXECUTABLE=$MAVEN_HOME/bin/mvn
  MAVEN_CONFIG_FILE=$MAVEN_HOME/conf/settings-$MAVEN_PROFILE.xml

  # validations
  if [[ -z $MAVEN_PROFILE ]]; then
    if [[ -n $MAVEN_PROFILE_DEFAULT_OVERRIDE ]]; then
      # if default maven profile is overrided, do not apply default configuration file if MAVEN_PROFILE is empty
      _maven_profiler_error "maven profile is empty, please check MAVEN_PROFILE variable"
      return 1
    else
      # apply default maven profile
      MAVEN_PROFILE=default
      MAVEN_CONFIG_FILE=$MAVEN_HOME/conf/settings.xml
    fi
  fi

  if [[ ! -f $MAVEN_EXECUTABLE ]]; then
    _maven_profiler_error "maven executable not found"
    return 1
  fi

  if [[ ! -f $MAVEN_CONFIG_FILE ]]; then
    _maven_profiler_error "maven configuration file [settings-$MAVEN_PROFILE.xml] not found"
    return 1
  fi

  # shellcheck disable=SC2207
  IFS=$'\n' JDK_VERSION_OUTPUT=($(java --version))
  _maven_profiler_prompt "jdk version" "${JDK_VERSION_OUTPUT[1]}"
  _maven_profiler_prompt "mvn profile" "${MAVEN_PROFILE}"
  _maven_profiler_prompt "mvn home" "${MAVEN_HOME}"
  # pause for a short time for human eye to catch up with the prompt message
  sleep 1

  # execute mvn with designate configuration file and passed options
  "$MAVEN_EXECUTABLE" -s "$MAVEN_CONFIG_FILE" "$@"
}

mvn-profiler-autoconfigure() {
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

_maven_profiler_load_env
unfunction _maven_profiler_load_env

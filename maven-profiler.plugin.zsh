#!/usr/bin/env zsh
#
# oh-my-zsh plugin entry point. All actual logic lives in mvnp-core.sh
# (shared with maven-profiler.entry.sh for standalone/bash usage), this
# file only sources it and wires up the interactive zsh aliases.

# load guard - avoid redefining everything / re-running core's side effects
# (e.g. clearing $MAVEN_PROFILE) if this plugin file is sourced more than once
if (( ${+_MVNP_PLUGIN_LOADED} )); then
  return 0
fi
typeset -g _MVNP_PLUGIN_LOADED=1

MVNP_PLUGIN_DIR="${0:A:h}"
source "$MVNP_PLUGIN_DIR/mvnp-core.sh"
unset MVNP_PLUGIN_DIR

# override default mvn command
# note: the real `mvn` binary is still reachable via `command mvn` or `\mvn`
alias mvnp=mvn-profiler
alias mvnp-switch=_mvnp_switch_profile
alias mvnp-show=_mvnp_show_profile


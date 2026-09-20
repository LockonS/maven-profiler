#!/usr/bin/env bash
#
# CLI entry point for maven-profiler, usable outside of oh-my-zsh.
#
# This file is processed by bash: it sources the shared mvnp-core.sh
# (written to work under both bash and zsh) and invokes mvn-profiler
# directly. No zsh installation is required to use this entry point.
#
# Usage: alias or symlink this file as `mvnp`, e.g.
#   alias mvnp="/path/to/maven-profiler/maven-profiler.entry.sh"
#   ln -s /path/to/maven-profiler/maven-profiler.entry.sh ~/.bin/mvnp

set -eo pipefail
# note: intentionally not using `set -u` - mvnp-core.sh relies on
# variables like $MAVEN_PROFILE / $MAVEN_HOME being safely readable
# even when unset

# resolve this script's real directory, so it also works via symlinks
_mvnp_entry_resolve_dir() {
  local SOURCE="${BASH_SOURCE[0]:-$0}"
  while [[ -L "$SOURCE" ]]; do
    local DIR
    DIR="$(cd -P "$(dirname "$SOURCE")" && pwd)"
    SOURCE="$(readlink "$SOURCE")"
    [[ "$SOURCE" != /* ]] && SOURCE="$DIR/$SOURCE"
  done
  cd -P "$(dirname "$SOURCE")" && pwd
}

MVNP_SCRIPT_DIR="$(_mvnp_entry_resolve_dir)"
MVNP_CORE_FILE="$MVNP_SCRIPT_DIR/mvnp-core.sh"

if [[ ! -f "$MVNP_CORE_FILE" ]]; then
  echo "[maven-profiler] unable to locate mvnp-core.sh next to this script" >&2
  exit 1
fi

# shellcheck source=mvnp-core.sh
source "$MVNP_CORE_FILE"

mvn-profiler "$@"


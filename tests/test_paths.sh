#!/usr/bin/env bash
# shellcheck disable=SC1091

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

declare -A RUNTIME_DIRS
declare -A TRASH_DIRS

source "${SCRIPT_DIR}/../src/lib/logger.sh"
source "${SCRIPT_DIR}/../src/lib/paths.sh"

test_path_detection() {
  local test_home="/tmp/test_home"
  local test_xdg="/tmp/test_xdg"

  mkdir -p "${test_home}/.local/share/jupyter/runtime"
  mkdir -p "${test_xdg}/jupyter"

  HOME=$test_home XDG_RUNTIME_DIR=$test_xdg detect_system_paths

  [[ ${#RUNTIME_DIRS[@]} -gt 0 ]] || {
    log_error "No runtime directories detected"
    exit 1
  }
  [[ -n "${RUNTIME_DIRS[local]:-}" ]] || {
    log_error "Local runtime dir not found"
    exit 1
  }

  rm -rf "$test_home" "$test_xdg"
}

test_permission_check() {
  local test_dir="/tmp/test_jupyter"
  mkdir -p "$test_dir"

  local old_umask
  old_umask=$(umask)
  umask 0000
  check_permissions
  umask "$old_umask"

  rm -rf "$test_dir"
}

test_disk_space() {
  local test_dir="/tmp/test_jupyter"
  mkdir -p "$test_dir"

  RUNTIME_DIRS=([test]="$test_dir")
  check_disk_space

  rm -rf "$test_dir"
}

main() {
  log_header "Running path tests"

  test_path_detection
  test_permission_check
  test_disk_space

  log_info "All path tests passed"
}

main "$@"

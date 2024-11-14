#!/usr/bin/env bash
# shellcheck disable=SC1091

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../src/lib/logger.sh"
source "${SCRIPT_DIR}/../src/lib/system.sh"

test_requirements() {
  if ! check_requirements; then
    log_error "Requirements check failed"
    return 1
  fi
  return 0
}

test_system_info() {
  local info
  info=$(get_system_info)

  [[ -n "$info" ]] || {
    log_error "System info is empty"
    return 1
  }
  [[ "$info" =~ "Kernel:" ]] || {
    log_error "Kernel info missing"
    return 1
  }
  [[ "$info" =~ "Memory:" ]] || {
    log_error "Memory info missing"
    return 1
  }

  return 0
}

main() {
  log_header "Running system tests"

  if ! test_requirements; then
    exit 1
  fi

  if ! test_system_info; then
    exit 1
  fi

  log_info "All system tests passed"
}

main "$@"

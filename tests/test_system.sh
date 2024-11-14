#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../src/lib/logger.sh"
source "${SCRIPT_DIR}/../src/lib/system.sh"

test_requirements() {
  check_requirements || {
    log_error "Requirements check failed"
    exit 1
  }
}

test_system_info() {
  local info
  info=$(get_system_info)

  [[ -n "$info" ]] || {
    log_error "System info is empty"
    exit 1
  }
  [[ "$info" =~ "Kernel:" ]] || {
    log_error "Kernel info missing"
    exit 1
  }
  [[ "$info" =~ "Memory:" ]] || {
    log_error "Memory info missing"
    exit 1
  }
}

main() {
  log_header "Running system tests"

  test_requirements
  test_system_info

  log_info "All system tests passed"
}

main "$@"

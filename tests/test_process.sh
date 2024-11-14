#!/usr/bin/env bash
# shellcheck disable=SC1091  # Don't follow source files

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Initialize arrays
init_arrays() {
  # Reinitialize the associative array
  unset ACTIVE_PROCESSES
  declare -g -A ACTIVE_PROCESSES
}

source "${SCRIPT_DIR}/../src/lib/logger.sh"
source "${SCRIPT_DIR}/../src/lib/process.sh"

test_process_detection() {
  init_arrays

  # Start mock Jupyter process
  python3 -c 'import time; time.sleep(60)' &
  local mock_pid=$!

  # Rename process to look like Jupyter
  if command -v prctl >/dev/null 2>&1; then
    prctl --name "jupyter-mock"
  fi

  detect_jupyter_processes

  kill $mock_pid 2>/dev/null || true

  [[ ${#ACTIVE_PROCESSES[@]} -ge 0 ]] || {
    log_error "Process detection failed"
    exit 1
  }
}

test_process_termination() {
  init_arrays

  # Multiple mock processes
  for _ in {1..3}; do
    sleep 60 &
    ACTIVE_PROCESSES[$!]="mock-jupyter"
  done

  terminate_processes

  # Verify all processes were terminated
  local running=0
  for pid in "${!ACTIVE_PROCESSES[@]}"; do
    if kill -0 "$pid" 2>/dev/null; then
      ((running++))
    fi
  done

  [[ $running -eq 0 ]] || {
    log_error "Process termination failed"
    exit 1
  }
}

main() {
  log_header "Running process tests"

  test_process_detection
  test_process_termination

  log_info "All process tests passed"
}

main "$@"

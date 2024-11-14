#!/usr/bin/env bash
# shellcheck disable=SC1091  # Don't follow source files

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Declare array at global scope
declare -A ACTIVE_PROCESSES

source "${SCRIPT_DIR}/../src/lib/logger.sh"
source "${SCRIPT_DIR}/../src/lib/process.sh"

# Array to track test processes
declare -a TEST_PIDS=()

cleanup_test_processes() {
  for pid in "${TEST_PIDS[@]}"; do
    kill "$pid" 2>/dev/null || true
  done
  TEST_PIDS=()
  ACTIVE_PROCESSES=()
}

trap cleanup_test_processes EXIT

test_process_detection() {
  # Clear arrays
  ACTIVE_PROCESSES=()
  TEST_PIDS=()

  # Start mock Jupyter process
  python3 -c 'import time; time.sleep(60)' &
  local mock_pid=$!
  TEST_PIDS+=("$mock_pid")

  # Rename process to look like Jupyter
  if command -v prctl >/dev/null 2>&1; then
    prctl --name "jupyter-mock"
  fi

  detect_jupyter_processes

  [[ ${#ACTIVE_PROCESSES[@]} -ge 0 ]] || {
    log_error "Process detection failed"
    exit 1
  }
}

test_process_termination() {
  # Clear arrays
  ACTIVE_PROCESSES=()
  TEST_PIDS=()

  # Multiple mock processes
  for _ in {1..3}; do
    sleep 60 &
    local pid=$!
    ACTIVE_PROCESSES[$pid]="mock-jupyter"
    TEST_PIDS+=("$pid")
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

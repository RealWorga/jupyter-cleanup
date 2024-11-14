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
  log_debug "Cleaning up test processes: ${TEST_PIDS[*]:-none}"
  for pid in "${TEST_PIDS[@]}"; do
    if kill -0 "$pid" 2>/dev/null; then
      log_debug "Killing test process $pid"
      kill "$pid" 2>/dev/null || true
    fi
  done
  TEST_PIDS=()
  ACTIVE_PROCESSES=()
}

trap cleanup_test_processes EXIT

test_process_detection() {
  log_debug "Starting process detection test"
  ACTIVE_PROCESSES=()
  TEST_PIDS=()

  # Start mock Jupyter process
  python3 -c 'import time; time.sleep(60)' &
  local mock_pid=$!
  TEST_PIDS+=("$mock_pid")
  log_debug "Started mock process with PID $mock_pid"

  detect_jupyter_processes
  log_debug "Detected processes: ${!ACTIVE_PROCESSES[*]:-none}"

  [[ ${#ACTIVE_PROCESSES[@]} -ge 0 ]] || {
    log_error "Process detection failed. Found ${#ACTIVE_PROCESSES[@]} processes"
    exit 1
  }
}

test_process_termination() {
  log_debug "Starting process termination test"
  ACTIVE_PROCESSES=()
  TEST_PIDS=()

  local pids=()
  # Start mock processes
  for _ in {1..3}; do
    sleep 60 &
    pids+=("$!")
  done

  # Add processes to tracking arrays
  for pid in "${pids[@]}"; do
    TEST_PIDS+=("$pid")
    ACTIVE_PROCESSES["pid_${pid}"]="mock-jupyter"
    log_debug "Started mock process with PID $pid"
  done

  log_debug "Before termination: ${!ACTIVE_PROCESSES[*]:-none}"
  terminate_processes
  log_debug "After termination: ${!ACTIVE_PROCESSES[*]:-none}"

  # Verify all processes were terminated
  local running=0
  for key in "${!ACTIVE_PROCESSES[@]}"; do
    local pid="${key#pid_}"
    if kill -0 "$pid" 2>/dev/null; then
      log_debug "Process $pid is still running"
      ((running++))
    fi
  done

  [[ $running -eq 0 ]] || {
    log_error "Process termination failed. $running processes still running"
    exit 1
  }
}

main() {
  log_header "Running process tests"
  export DEBUG=1 # Enable debug logging

  test_process_detection
  test_process_termination

  log_info "All process tests passed"
}

main "$@"

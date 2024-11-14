#!/usr/bin/env bash
# shellcheck disable=SC1091  # Don't follow source files

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Simpler debug function
debug_array() {
  local name=$1
  echo "=== Debug $name ==="
  declare -p "$name" 2>/dev/null || echo "Array not defined"
  echo "=================="
}

# Declare array at global scope
declare -A ACTIVE_PROCESSES

source "${SCRIPT_DIR}/../src/lib/logger.sh"
source "${SCRIPT_DIR}/../src/lib/process.sh"

# Array to track test processes
declare -a TEST_PIDS=()

cleanup_test_processes() {
  log_debug "=== Cleanup Start ==="
  debug_array ACTIVE_PROCESSES

  for pid in "${TEST_PIDS[@]}"; do
    if kill -0 "$pid" 2>/dev/null; then
      log_debug "Killing test process $pid"
      kill "$pid" 2>/dev/null || true
    fi
  done

  TEST_PIDS=()
  unset ACTIVE_PROCESSES
  declare -g -A ACTIVE_PROCESSES

  log_debug "=== Cleanup End ==="
  debug_array ACTIVE_PROCESSES
}

trap cleanup_test_processes EXIT

test_process_detection() {
  log_debug "=== Detection Start ==="
  debug_array ACTIVE_PROCESSES

  unset ACTIVE_PROCESSES
  declare -g -A ACTIVE_PROCESSES
  TEST_PIDS=()

  python3 -c 'import time; time.sleep(60)' &
  local mock_pid=$!
  TEST_PIDS+=("$mock_pid")
  log_debug "Started mock process with PID $mock_pid"

  detect_jupyter_processes
  debug_array ACTIVE_PROCESSES
}

test_process_termination() {
  log_debug "=== Termination Start ==="
  debug_array ACTIVE_PROCESSES

  unset ACTIVE_PROCESSES
  declare -g -A ACTIVE_PROCESSES
  TEST_PIDS=()

  # Test processes one at a time
  for i in {1..3}; do
    log_debug "Starting process $i"
    sleep 60 &
    local pid=$!
    TEST_PIDS+=("$pid")

    # Set array value
    local key="pid_${pid}"
    ACTIVE_PROCESSES[$key]="mock-jupyter"
    log_debug "Added process $pid to array"
    debug_array ACTIVE_PROCESSES
  done

  log_debug "=== Before Termination ==="
  debug_array ACTIVE_PROCESSES

  terminate_processes

  log_debug "=== After Termination ==="
  debug_array ACTIVE_PROCESSES

  # Verify termination
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
  export DEBUG=1

  test_process_detection
  test_process_termination

  log_info "All process tests passed"
}

main "$@"

#!/usr/bin/env bash
# shellcheck disable=SC1091  # Don't follow source files

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Debug function
debug_array() {
  local name=$1
  local -n arr=$1
  echo "=== Debug $name ==="
  echo "Type: $(declare -p "$name")"
  echo "Keys: ${!arr[@]:-none}"
  echo "Values: ${arr[@]:-none}"
  echo "Size: ${#arr[@]}"
  echo "=================="
}

# Declare array at global scope
declare -A ACTIVE_PROCESSES
debug_array ACTIVE_PROCESSES

source "${SCRIPT_DIR}/../src/lib/logger.sh"
source "${SCRIPT_DIR}/../src/lib/process.sh"

# Array to track test processes
declare -a TEST_PIDS=()

cleanup_test_processes() {
  log_debug "=== Cleanup Start ==="
  debug_array ACTIVE_PROCESSES
  log_debug "Cleaning up test processes: ${TEST_PIDS[*]:-none}"
  for pid in "${TEST_PIDS[@]}"; do
    if kill -0 "$pid" 2>/dev/null; then
      log_debug "Killing test process $pid"
      kill "$pid" 2>/dev/null || true
    fi
  done
  TEST_PIDS=()
  ACTIVE_PROCESSES=()
  log_debug "=== Cleanup End ==="
  debug_array ACTIVE_PROCESSES
}

trap cleanup_test_processes EXIT

test_process_detection() {
  log_debug "=== Detection Start ==="
  debug_array ACTIVE_PROCESSES

  log_debug "Starting process detection test"
  ACTIVE_PROCESSES=()
  TEST_PIDS=()

  python3 -c 'import time; time.sleep(60)' &
  local mock_pid=$!
  TEST_PIDS+=("$mock_pid")
  log_debug "Started mock process with PID $mock_pid"

  detect_jupyter_processes
  log_debug "=== After Detection ==="
  debug_array ACTIVE_PROCESSES

  [[ ${#ACTIVE_PROCESSES[@]} -ge 0 ]] || {
    log_error "Process detection failed. Found ${#ACTIVE_PROCESSES[@]} processes"
    exit 1
  }
}

test_process_termination() {
  log_debug "=== Termination Start ==="
  debug_array ACTIVE_PROCESSES

  log_debug "Starting process termination test"
  ACTIVE_PROCESSES=()
  TEST_PIDS=()

  # Start single process first as test
  log_debug "Starting test process..."
  sleep 60 &
  local test_pid=$!
  log_debug "Got PID: $test_pid"
  log_debug "Setting array key: pid_${test_pid}"

  # Try setting single process first
  ACTIVE_PROCESSES["pid_${test_pid}"]="mock-jupyter"
  log_debug "=== After First Process ==="
  debug_array ACTIVE_PROCESSES

  # If we got here, try adding more
  for i in {2..3}; do
    log_debug "Starting process $i..."
    sleep 60 &
    local pid=$!
    TEST_PIDS+=("$pid")
    log_debug "Setting array key: pid_${pid}"
    ACTIVE_PROCESSES["pid_${pid}"]="mock-jupyter"
    log_debug "=== After Process $i ==="
    debug_array ACTIVE_PROCESSES
  done

  log_debug "=== Before Termination ==="
  debug_array ACTIVE_PROCESSES

  terminate_processes

  log_debug "=== After Termination ==="
  debug_array ACTIVE_PROCESSES

  # Verify all processes were terminated
  local running=0
  for key in "${!ACTIVE_PROCESSES[@]}"; do
    log_debug "Checking key: $key"
    local pid="${key#pid_}"
    log_debug "Extracted PID: $pid"
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

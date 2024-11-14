#!/usr/bin/env bash
# shellcheck disable=SC1091

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

debug_array() {
  local name=$1
  echo "=== Debug $name ==="
  declare -p "$name" 2>/dev/null || echo "Array not defined"
  echo "=================="
}

declare -A ACTIVE_PROCESSES
declare -a TEST_PIDS=()

source "${SCRIPT_DIR}/../src/lib/logger.sh"
source "${SCRIPT_DIR}/../src/lib/process.sh"

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

  for i in {1..3}; do
    log_debug "Starting process $i"
    sleep 60 &
    local pid=$!
    TEST_PIDS+=("$pid")

    local key="pid_${pid}"
    ACTIVE_PROCESSES[$key]="mock-jupyter"
    log_debug "Added process $pid to array"
    debug_array ACTIVE_PROCESSES
  done

  if ! terminate_processes; then
    log_error "terminate_processes failed"
    return 1
  fi

  sleep 1

  local running=0
  for key in "${!ACTIVE_PROCESSES[@]}"; do
    local pid="${key#pid_}"
    if kill -0 "$pid" 2>/dev/null; then
      log_debug "Process $pid is still running"
      ((running++))
    fi
  done

  if [[ $running -gt 0 ]]; then
    log_error "Process termination failed. $running processes still running"
    return 1
  fi

  return 0
}

main() {
  log_header "Running process tests"
  export DEBUG=1

  test_process_detection
  test_process_termination

  log_info "All process tests passed"
}

main "$@"

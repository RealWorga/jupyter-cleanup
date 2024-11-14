#!/usr/bin/env bash

set -euo pipefail
IFS=$'\n\t'

# Load configs and utils
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib/logger.sh"
source "${SCRIPT_DIR}/lib/paths.sh"
source "${SCRIPT_DIR}/lib/process.sh"
source "${SCRIPT_DIR}/lib/system.sh"

# Initialize arrays
declare -A RUNTIME_DIRS
# shellcheck disable=SC2034  # Used in sourced files
declare -A TRASH_DIRS
declare -A ACTIVE_PROCESSES

# Status tracking
declare -i EXIT_CODE=0

cleanup_handler() {
  local exit_code=$?
  exec 1>&3 2>&4
  if [ $exit_code -ne 0 ]; then
    log_error "Cleanup failed with code $exit_code"
    exit_code=1
  fi
  exit $exit_code
}

error_handler() {
  local line_no=$1
  local command=$2
  log_error "Failed at line ${line_no}: ${command}"
  EXIT_CODE=1
}

init_logging() {
  LOG_FILE="${XDG_STATE_HOME:-$HOME/.local/state}/jupyter-cleanup/cleanup-$(date +%Y%m%d).log"
  mkdir -p "$(dirname "$LOG_FILE")"
  exec 3>&1 4>&2
  exec 1> >(tee -a "$LOG_FILE") 2>&1
}

verify_environment() {
  log_debug "Verifying environment..."

  log_debug "Checking requirements..."
  check_requirements || {
    log_error "System requirements check failed"
    return 1
  }

  log_debug "Checking permissions..."
  check_permissions || {
    log_debug "Permission check passed (warnings are okay)"
  }

  log_debug "Validating paths..."
  validate_paths || {
    log_error "Path validation failed"
    return 1
  }

  log_debug "Checking disk space..."
  check_disk_space || {
    log_debug "Disk space check passed (warnings are okay)"
  }

  return 0
}

main() {
  trap cleanup_handler EXIT
  trap error_handler ERR
  trap 'exit 130' INT

  init_logging
  export DEBUG=1 # Enable debug logging for CI
  log_header "Starting Jupyter cleanup"

  # Initialize environment
  log_debug "Detecting system paths..."
  detect_system_paths || EXIT_CODE=1

  log_debug "Verifying environment..."
  verify_environment || EXIT_CODE=1

  # Main cleanup tasks
  if [ $EXIT_CODE -eq 0 ]; then
    handle_running_processes || EXIT_CODE=1
    clean_runtime_directories || EXIT_CODE=1
    verify_cleanup || EXIT_CODE=1
  else
    log_error "Environment verification failed, skipping cleanup"
  fi

  if [ $EXIT_CODE -eq 0 ]; then
    log_header "Cleanup completed successfully"
  else
    log_error "Cleanup completed with errors"
    return 1
  fi
}

main "$@"

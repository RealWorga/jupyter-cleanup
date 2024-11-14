#!/usr/bin/env bash

set -euo pipefail
IFS=$'\n\t'

# Load configs and utils
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib/logger.sh"
source "${SCRIPT_DIR}/lib/paths.sh"
source "${SCRIPT_DIR}/lib/process.sh"
source "${SCRIPT_DIR}/lib/system.sh"

trap cleanup_handler EXIT
trap error_handler ERR
trap 'exit 130' INT

# shellcheck disable=SC2034
declare -A RUNTIME_DIRS
# shellcheck disable=SC2034
declare -A TRASH_DIRS
# shellcheck disable=SC2034
declare -A ACTIVE_PROCESSES

main() {
  init_logging
  detect_system_paths
  verify_environment

  log_header "Starting Jupyter cleanup"

  handle_running_processes
  clean_runtime_directories
  verify_cleanup

  log_header "Cleanup completed successfully"
}

init_logging() {
  LOG_FILE="${XDG_STATE_HOME:-$HOME/.local/state}/jupyter-cleanup/cleanup-$(date +%Y%m%d).log"
  mkdir -p "$(dirname "$LOG_FILE")"
  exec 3>&1 4>&2
  exec 1> >(tee -a "$LOG_FILE") 2>&1
}

verify_environment() {
  check_permissions
  validate_paths
  check_disk_space
}

cleanup_handler() {
  local exit_code=$?
  exec 1>&3 2>&4
  [ $exit_code -ne 0 ] && log_error "Cleanup failed with code $exit_code"
  return $exit_code
}

error_handler() {
  local line_no=$1
  local command=$2
  log_error "Failed at line ${line_no}: ${command}"
}

main "$@"

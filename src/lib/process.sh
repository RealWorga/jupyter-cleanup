#!/usr/bin/env bash

handle_running_processes() {
  detect_jupyter_processes
  terminate_processes
}

detect_jupyter_processes() {
  local pids
  mapfile -t pids < <(pgrep -U "$UID" -f "jupyter-notebook|jupyter-lab|jupyter-server" 2>/dev/null || true)

  for pid in "${pids[@]}"; do
    if [[ -n "$pid" ]]; then
      local cmdline
      cmdline=$(tr '\0' ' ' <"/proc/${pid}/cmdline" 2>/dev/null || echo "")
      if [[ "$cmdline" =~ jupyter-(notebook|lab|server) ]]; then
        ACTIVE_PROCESSES["pid_${pid}"]=$cmdline
        log_debug "Found Jupyter process $pid: $cmdline"
      else
        log_debug "Skipping non-Jupyter process $pid: $cmdline"
      fi
    fi
  done
}

terminate_processes() {
  local terminated=0

  for key in "${!ACTIVE_PROCESSES[@]}"; do
    local pid="${key#pid_}"
    log_debug "Attempting to terminate process $pid"

    if kill -0 "$pid" 2>/dev/null; then
      log_info "Terminating Jupyter process $pid: ${ACTIVE_PROCESSES[$key]}"
      kill -TERM "$pid" 2>/dev/null

      local i
      for ((i = 0; i < 5; i++)); do
        if ! kill -0 "$pid" 2>/dev/null; then
          ((terminated++))
          break
        fi
        sleep 1
      done

      if kill -0 "$pid" 2>/dev/null; then
        log_warn "Force killing process $pid"
        kill -9 "$pid" 2>/dev/null
        sleep 1
        ((terminated++))
      fi
    fi
  done

  log_info "Terminated $terminated processes"
  return 0
}

clean_runtime_directories() {
  local removed=0

  for dir in "${RUNTIME_DIRS[@]}"; do
    if [[ -d "$dir" ]]; then
      log_info "Cleaning directory: $dir"
      find "$dir" -name "*.json" -type f -delete 2>/dev/null
      find "$dir" -type d -empty -delete 2>/dev/null
      ((removed++))
    fi
  done

  log_info "Cleaned $removed directories"
  return 0
}

verify_cleanup() {
  local active_count
  active_count=$(pgrep -U "$UID" -f "jupyter-notebook|jupyter-lab|jupyter-server" 2>/dev/null | wc -l)

  if [[ $active_count -gt 0 ]]; then
    log_warn "$active_count Jupyter processes still running"
    return 1
  else
    log_info "All Jupyter processes successfully terminated"
    return 0
  fi
}

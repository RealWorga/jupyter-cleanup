#!/usr/bin/env bash

handle_running_processes() {
  detect_jupyter_processes
  terminate_processes
}

detect_jupyter_processes() {
  local pids

  mapfile -t pids < <(pgrep -U "$UID" -f "jupyter-" 2>/dev/null || true)

  for pid in "${pids[@]}"; do
    if [[ -n "$pid" ]]; then
      local cmdline
      cmdline=$(tr '\0' ' ' <"/proc/${pid}/cmdline" 2>/dev/null || echo "")
      ACTIVE_PROCESSES[$pid]=$cmdline
      log_debug "Found Jupyter process $pid: $cmdline"
    fi
  done
}

terminate_processes() {
  local terminated=0

  for pid in "${!ACTIVE_PROCESSES[@]}"; do
    if kill -0 "$pid" 2>/dev/null; then
      log_info "Terminating Jupyter process $pid: ${ACTIVE_PROCESSES[$pid]}"

      # Graceful shutdown firsthand
      kill -TERM "$pid" 2>/dev/null

      for ((i = 0; i < 5; i++)); do
        if ! kill -0 "$pid" 2>/dev/null; then
          ((terminated++))
          break
        fi
        sleep 1
      done

      # Force kill if still running
      if kill -0 "$pid" 2>/dev/null; then
        log_warn "Force killing process $pid"
        kill -9 "$pid" 2>/dev/null
        ((terminated++))
      fi
    fi
  done

  log_info "Terminated $terminated Jupyter processes"
}

clean_runtime_directories() {
  local removed=0

  for dir in "${RUNTIME_DIRS[@]}"; do
    if [[ -d "$dir" ]]; then
      log_info "Cleaning directory: $dir"

      # Remove JSON files older than a day
      find "$dir" -name "*.json" -type f -mtime +1 -delete 2>/dev/null

      # Remove empty dirs
      find "$dir" -type d -empty -delete 2>/dev/null

      ((removed++))
    fi
  done

  log_info "Cleaned $removed directories"
}

verify_cleanup() {
  local active_count
  active_count=$(pgrep -U "$UID" -f "jupyter-" 2>/dev/null | wc -l)

  if [[ $active_count -gt 0 ]]; then
    log_warn "$active_count Jupyter processes still running"
  else
    log_info "All Jupyter processes successfully terminated"
  fi
}

#!/usr/bin/env bash
# shellcheck disable=SC2034  # TRASH_DIRS is used in main script

detect_system_paths() {
  local jupyter_cmd=""

  # Find Jupyter executable location
  jupyter_cmd=$(command -v jupyter || true)

  if [[ -n "$jupyter_cmd" ]]; then
    # Get data dir from Jupyter itself
    local jupyter_data_dir=""
    jupyter_data_dir=$(jupyter --data-dir 2>/dev/null || echo "")

    if [[ -n "$jupyter_data_dir" ]]; then
      RUNTIME_DIRS["jupyter_data"]="${jupyter_data_dir}/runtime"
    fi
  fi

  RUNTIME_DIRS["local"]="${HOME}/.local/share/jupyter/runtime"
  RUNTIME_DIRS["xdg"]="${XDG_RUNTIME_DIR:-/run/user/$UID}/jupyter"

  if [[ -d "${HOME}/.local/share/Trash" ]]; then
    TRASH_DIRS["freedesktop"]="${HOME}/.local/share/Trash"
  fi

  validate_paths
  return 0 # Always return success, validation is separate
}

validate_paths() {
  local valid_paths=0
  log_debug "Validating paths..."

  # Check if we have any paths defined
  if [[ ${#RUNTIME_DIRS[@]} -eq 0 ]]; then
    log_error "No runtime directories configured"
    return 1
  fi

  for key in "${!RUNTIME_DIRS[@]}"; do
    local dir="${RUNTIME_DIRS[$key]}"
    if [[ -d "$dir" && -r "$dir" && -w "$dir" ]]; then
      ((valid_paths++))
      log_debug "Valid runtime directory found: $dir"
    else
      log_debug "Invalid or inaccessible directory: $dir"
      unset "RUNTIME_DIRS[$key]"
    fi
  done

  # After validation, check if we have at least one valid path
  if [[ $valid_paths -eq 0 ]]; then
    log_error "No valid Jupyter runtime directories found"
    return 1
  fi

  return 0
}

check_permissions() {
  local current_umask
  current_umask=$(umask)
  if [[ $current_umask -eq 0000 ]]; then
    log_warn "Current umask is too permissive: $current_umask"
  fi
  return 0 # Always return success, this is just a warning
}

check_disk_space() {
  local min_space=100000 # 100MB in KB
  local available
  local has_error=0

  for dir in "${RUNTIME_DIRS[@]}"; do
    if [[ -d "$dir" ]]; then
      available=$(df -k "$(dirname "$dir")" | awk 'NR==2 {print $4}')
      if [[ $available -lt $min_space ]]; then
        log_warn "Low disk space in $(dirname "$dir"): ${available}KB available"
        has_error=1
      fi
    fi
  done

  return "$has_error"
}

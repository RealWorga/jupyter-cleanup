#!/usr/bin/env bash
# shellcheck disable=SC1091

readonly REQUIRED_COMMANDS=(pgrep kill find df free)

check_requirements() {
  local missing=0

  for cmd in "${REQUIRED_COMMANDS[@]}"; do
    if ! command -v "$cmd" >/dev/null 2>&1; then
      log_error "Required command not found: $cmd"
      ((missing++))
    fi
  done

  return "$missing"
}

get_system_info() {
  local info=""

  if [[ -f /etc/os-release ]]; then
    info+="OS: $(source /etc/os-release && echo "$NAME $VERSION_ID")\n"
  fi

  info+="Kernel: $(uname -r)\n"
  info+="Memory: $(free -h | awk '/^Mem:/ {print $2}')\n"

  echo -e "$info"
}

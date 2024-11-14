#!/usr/bin/env bash

# ANSI color codes
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m'

log_header() {
  local msg=$1
  echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')] ${msg}${NC}"
}

log_info() {
  local msg=$1
  echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')] ${msg}${NC}"
}

log_warn() {
  local msg=$1
  echo -e "${YELLOW}[$(date +'%Y-%m-%d %H:%M:%S')] ${msg}${NC}"
}

log_error() {
  local msg=$1
  echo -e "${RED}[$(date +'%Y-%m-%d %H:%M:%S')] ERROR: ${msg}${NC}" >&2
}

log_debug() {
  [[ ${DEBUG:-0} -eq 1 ]] && echo -e "[DEBUG] $1"
}

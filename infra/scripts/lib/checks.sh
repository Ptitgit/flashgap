#!/usr/bin/env bash
# Shared validation helpers for VPS provision smoke tests.
set -euo pipefail

# Extract root filesystem size in GB (integer) from `df -h` output.
parse_disk_gb_from_df() {
  local df_output="$1"
  local size
  size="$(echo "${df_output}" | awk '$6=="/" {print $2; exit}')"
  if [[ -z "${size}" ]]; then
    echo "0"
    return
  fi
  if [[ "${size}" =~ ^([0-9]+)G$ ]]; then
    echo "${BASH_REMATCH[1]}"
    return
  fi
  if [[ "${size}" =~ ^([0-9]+)T$ ]]; then
    echo $((BASH_REMATCH[1] * 1024))
    return
  fi
  echo "0"
}

is_ubuntu_lts() {
  local os_release="$1"
  if [[ "${os_release}" =~ Ubuntu\ ([0-9]{2})\.04 ]]; then
    return 0
  fi
  return 1
}

sshd_password_auth_disabled() {
  local sshd_config="$1"
  if echo "${sshd_config}" | grep -qiE '^[[:space:]]*PasswordAuthentication[[:space:]]+no'; then
    echo "yes"
    return 0
  fi
  echo "no"
  return 1
}

ufw_ssh_restricted() {
  local ufw_status="$1"
  if echo "${ufw_status}" | grep -qE '22/tcp[[:space:]]+ALLOW[[:space:]]+[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+'; then
    echo "yes"
    return 0
  fi
  echo "no"
  return 1
}

ufw_http_https_open() {
  local ufw_status="$1"
  local has_80 has_443
  has_80="$(echo "${ufw_status}" | grep -cE '80/tcp[[:space:]]+ALLOW' || true)"
  has_443="$(echo "${ufw_status}" | grep -cE '443/tcp[[:space:]]+ALLOW' || true)"
  if [[ "${has_80}" -ge 1 && "${has_443}" -ge 1 ]]; then
    return 0
  fi
  return 1
}

require_env() {
  local name="$1"
  if [[ -z "${!name:-}" ]]; then
    echo "Missing required environment variable: ${name}" >&2
    return 1
  fi
  return 0
}

min_disk_gb() {
  echo "20"
}

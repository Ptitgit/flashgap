#!/usr/bin/env bash
# Smoke test: validates a provisioned Flashgap VPS (run from dev machine via SSH).
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=lib/checks.sh
source "${ROOT_DIR}/scripts/lib/checks.sh"

if [[ -f "${ROOT_DIR}/host.env" ]]; then
  # shellcheck disable=SC1091
  source "${ROOT_DIR}/host.env"
fi

FLASHGAP_SSH_HOST="${FLASHGAP_SSH_HOST:-}"
FLASHGAP_SSH_USER="${FLASHGAP_SSH_USER:-deploy}"
FLASHGAP_SSH_PORT="${FLASHGAP_SSH_PORT:-22}"
FLASHGAP_SSH_RESTRICT_IP="${FLASHGAP_SSH_RESTRICT_IP:-}"
FLASHGAP_PUBLIC_HOSTNAME="${FLASHGAP_PUBLIC_HOSTNAME:-}"

FAILURES=0

fail() {
  echo "FAIL: $*" >&2
  FAILURES=$((FAILURES + 1))
}

pass() {
  echo "ok: $*"
}

ssh_cmd() {
  ssh -o BatchMode=yes -o ConnectTimeout=10 -p "${FLASHGAP_SSH_PORT}" \
    "${FLASHGAP_SSH_USER}@${FLASHGAP_SSH_HOST}" "$@"
}

require_env FLASHGAP_SSH_HOST || exit 1

if [[ -z "${FLASHGAP_SSH_RESTRICT_IP}" ]]; then
  fail "FLASHGAP_SSH_RESTRICT_IP must be set (UFW must restrict SSH to your IP or VPN)"
fi

if [[ -z "${FLASHGAP_PUBLIC_HOSTNAME}" ]]; then
  fail "FLASHGAP_PUBLIC_HOSTNAME must be set (documented in infra/README.md)"
fi

echo "Smoke VPS provision — ${FLASHGAP_SSH_USER}@${FLASHGAP_SSH_HOST}:${FLASHGAP_SSH_PORT}"

# SSH key-only (BatchMode fails if password required)
if ssh_cmd "true"; then
  pass "SSH key authentication as ${FLASHGAP_SSH_USER}"
else
  fail "SSH key authentication as ${FLASHGAP_SSH_USER}"
fi

if [[ "${FLASHGAP_SSH_USER}" == "deploy" ]]; then
  pass "login user is deploy"
else
  fail "FLASHGAP_SSH_USER must be deploy (got ${FLASHGAP_SSH_USER})"
fi

if ssh_cmd "sudo -n /usr/sbin/ufw status" 2>/dev/null; then
  pass "deploy has passwordless sudo for ufw (limited in /etc/sudoers.d/deploy)"
else
  fail "deploy cannot sudo -n ufw (check /etc/sudoers.d/deploy)"
fi

OS_RELEASE="$(ssh_cmd "cat /etc/os-release" 2>/dev/null || true)"
if is_ubuntu_lts "${OS_RELEASE}"; then
  pass "OS is Ubuntu LTS"
else
  fail "OS is not Ubuntu LTS — ${OS_RELEASE}"
fi

DF_OUTPUT="$(ssh_cmd "df -h /" 2>/dev/null || true)"
DISK_GB="$(parse_disk_gb_from_df "${DF_OUTPUT}")"
MIN_GB="$(min_disk_gb)"
if [[ "${DISK_GB}" -ge "${MIN_GB}" ]]; then
  pass "root disk >= ${MIN_GB} GB (${DISK_GB} GB)"
else
  fail "root disk < ${MIN_GB} GB (${DISK_GB} GB)"
fi

SSHD_CONFIG="$(ssh_cmd "sudo cat /etc/ssh/sshd_config /etc/ssh/sshd_config.d/*.conf 2>/dev/null" || true)"
if [[ "$(sshd_password_auth_disabled "${SSHD_CONFIG}")" == "yes" ]]; then
  pass "PasswordAuthentication disabled"
else
  fail "PasswordAuthentication is not disabled in sshd_config"
fi

UFW_STATUS="$(ssh_cmd "sudo ufw status verbose" 2>/dev/null || true)"
if ufw_http_https_open "${UFW_STATUS}"; then
  pass "UFW allows 80/tcp and 443/tcp"
else
  fail "UFW must allow 80/tcp and 443/tcp"
fi

if [[ "$(ufw_ssh_restricted "${UFW_STATUS}")" == "yes" ]]; then
  pass "UFW restricts SSH (22) to a single IP"
else
  fail "UFW must restrict 22/tcp to FLASHGAP_SSH_RESTRICT_IP (not Anywhere)"
fi

echo "---"
if [[ "${FAILURES}" -gt 0 ]]; then
  echo "${FAILURES} check(s) failed"
  exit 1
fi
echo "All smoke checks passed for ${FLASHGAP_PUBLIC_HOSTNAME} (${FLASHGAP_SSH_HOST})"

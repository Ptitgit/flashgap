#!/usr/bin/env bash
# Unit tests for infra/scripts/lib/checks.sh (TDD — no SSH required)
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../../scripts/lib/checks.sh
source "${SCRIPT_DIR}/../../scripts/lib/checks.sh"

TESTS_RUN=0
TESTS_FAILED=0

assert_eq() {
  local expected="$1"
  local actual="$2"
  local label="$3"
  TESTS_RUN=$((TESTS_RUN + 1))
  if [[ "${expected}" != "${actual}" ]]; then
    echo "FAIL: ${label} — expected '${expected}', got '${actual}'"
    TESTS_FAILED=$((TESTS_FAILED + 1))
  else
    echo "ok: ${label}"
  fi
}

assert_exit() {
  local expected_code="$1"
  shift
  TESTS_RUN=$((TESTS_RUN + 1))
  set +e
  "$@" >/dev/null 2>&1
  local code=$?
  set -e
  if [[ "${code}" -ne "${expected_code}" ]]; then
    echo "FAIL: exit code for $* — expected ${expected_code}, got ${code}"
    TESTS_FAILED=$((TESTS_FAILED + 1))
  else
    echo "ok: exit $* => ${expected_code}"
  fi
}

# --- parse_disk_gb_from_df ---

assert_eq "20" "$(parse_disk_gb_from_df "Filesystem      Size  Used Avail Use% Mounted on
/dev/sda1        20G  2.0G   17G  11% /")" "parse_disk_gb whole GB"

assert_eq "25" "$(parse_disk_gb_from_df "/dev/vda1        25G  1.0G   24G   5% /")" "parse_disk_gb 25G root"

# --- is_ubuntu_lts ---

assert_eq "yes" "$(is_ubuntu_lts "PRETTY_NAME=\"Ubuntu 24.04.1 LTS\"" && echo yes || echo no)" "ubuntu 24.04 LTS"

assert_eq "no" "$(is_ubuntu_lts "PRETTY_NAME=\"Debian GNU/Linux 12\"" && echo yes || echo no)" "debian not ubuntu"

# --- sshd_password_auth_disabled ---

assert_eq "yes" "$(sshd_password_auth_disabled "PasswordAuthentication no
PermitRootLogin prohibit-password")" "password auth off"

assert_eq "no" "$(sshd_password_auth_disabled "PasswordAuthentication yes")" "password auth on"

# --- ufw_ssh_restricted ---

assert_eq "yes" "$(ufw_ssh_restricted "Status: active
22/tcp                     ALLOW       203.0.113.10")" "ufw ssh restricted to IP"

assert_eq "no" "$(ufw_ssh_restricted "Status: active
22/tcp                     ALLOW       Anywhere")" "ufw ssh open to anywhere"

# --- require_env ---

assert_exit 1 require_env FLASHGAP_MISSING_VAR_TEST

export FLASHGAP_PRESENT_VAR_TEST=1
assert_exit 0 require_env FLASHGAP_PRESENT_VAR_TEST

echo "---"
echo "Ran ${TESTS_RUN} assertions, ${TESTS_FAILED} failed"
if [[ "${TESTS_FAILED}" -gt 0 ]]; then
  exit 1
fi

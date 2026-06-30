#!/usr/bin/env bash
# Unit tests for infra/scripts/deploy.sh (TDD — dry-run only, no Docker required)
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
DEPLOY_SCRIPT="${ROOT}/scripts/deploy.sh"
README="${ROOT}/README.md"

TESTS_RUN=0
TESTS_FAILED=0

assert_ok() {
  local label="$1"
  shift
  TESTS_RUN=$((TESTS_RUN + 1))
  if "$@"; then
    echo "ok: ${label}"
  else
    echo "FAIL: ${label}"
    TESTS_FAILED=$((TESTS_FAILED + 1))
  fi
}

assert_output_contains() {
  local needle="$1"
  shift
  local output
  output="$("$@")"
  grep -qF "${needle}" <<<"${output}"
}

assert_ok "deploy script exists" test -f "${DEPLOY_SCRIPT}"
assert_ok "deploy script is executable" test -x "${DEPLOY_SCRIPT}"

assert_ok "dry-run mentions git pull" \
  assert_output_contains "git pull" "${DEPLOY_SCRIPT}" --dry-run

assert_ok "dry-run mentions docker compose up -d --build" \
  assert_output_contains "docker compose up -d --build" "${DEPLOY_SCRIPT}" --dry-run

assert_ok "dry-run mentions docker compose logs -f api" \
  assert_output_contains "docker compose logs -f api" "${DEPLOY_SCRIPT}" logs --dry-run

assert_ok "README documents git pull redeploy" \
  grep -q 'git pull' "${README}"

assert_ok "README documents docker compose up -d --build" \
  grep -q 'docker compose up -d --build' "${README}"

assert_ok "README documents docker compose logs -f api" \
  grep -q 'docker compose logs -f api' "${README}"

assert_ok "README documents first deploy clone" \
  grep -qiE 'git clone|clone.*repo' "${README}"

assert_ok "README documents .env setup" \
  grep -qE 'cp.*\.env\.example.*\.env|\.env\.example.*\.env' "${README}"

echo "---"
echo "Ran ${TESTS_RUN} assertions, ${TESTS_FAILED} failed"
if [[ "${TESTS_FAILED}" -gt 0 ]]; then
  exit 1
fi

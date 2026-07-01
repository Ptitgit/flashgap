#!/usr/bin/env bash
# Unit tests for infra/scripts/lib/github-webhook.sh (TDD — no VPS required)
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../../scripts/lib/github-webhook.sh
source "${SCRIPT_DIR}/../../scripts/lib/github-webhook.sh"

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

assert_fail() {
  local label="$1"
  shift
  TESTS_RUN=$((TESTS_RUN + 1))
  if "$@"; then
    echo "FAIL: ${label} (expected failure)"
    TESTS_FAILED=$((TESTS_FAILED + 1))
  else
    echo "ok: ${label}"
  fi
}

TEST_SECRET="test-webhook-secret"
TEST_BODY='{"ref":"refs/heads/main","repository":{"full_name":"Ptitgit/flashgap"}}'

SIG="$(github_webhook_compute_signature "${TEST_SECRET}" "${TEST_BODY}")"

assert_eq "sha256=" "${SIG:0:7}" "signature prefix sha256="

assert_ok "valid signature accepted" github_webhook_verify_signature \
  "${TEST_SECRET}" "${SIG}" "${TEST_BODY}"

assert_fail "wrong secret rejected" github_webhook_verify_signature \
  "wrong-secret" "${SIG}" "${TEST_BODY}"

assert_fail "empty signature rejected" github_webhook_verify_signature \
  "${TEST_SECRET}" "" "${TEST_BODY}"

assert_eq "refs/heads/main" \
  "$(github_webhook_extract_ref "${TEST_BODY}")" \
  "extract ref from push payload"

assert_ok "main push detected" github_webhook_is_main_push \
  "push" "refs/heads/main"

assert_fail "non-main branch ignored" github_webhook_is_main_push \
  "push" "refs/heads/develop"

assert_fail "non-push event ignored" github_webhook_is_main_push \
  "ping" "refs/heads/main"

OTHER_BODY='{"ref":"refs/heads/feature/foo"}'
assert_eq "refs/heads/feature/foo" \
  "$(github_webhook_extract_ref "${OTHER_BODY}")" \
  "extract feature branch ref"

echo "---"
echo "Ran ${TESTS_RUN} assertions, ${TESTS_FAILED} failed"
if [[ "${TESTS_FAILED}" -gt 0 ]]; then
  exit 1
fi

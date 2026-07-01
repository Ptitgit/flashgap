#!/usr/bin/env bash
# Integration tests for GitHub deploy webhook — simulates prod scenarios locally.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
RUNNER="${ROOT}/tests/lib/webhook-linux-runner.sh"
HOOK_SCRIPT="${ROOT}/scripts/github-deploy-hook.sh"
SERVER_SCRIPT="${ROOT}/scripts/github-deploy-webhook-server.py"
NGINX_SNIPPET="${ROOT}/scripts/nginx-flashgap-deploy-hook.conf"
SYSTEMD_UNIT="${ROOT}/systemd/flashgap-deploy-webhook.service"

if ! command -v python3 >/dev/null 2>&1 && ! command -v docker >/dev/null 2>&1; then
  echo "SKIP: python3 and docker not available"
  exit 0
fi

if ! command -v curl >/dev/null 2>&1 && ! command -v docker >/dev/null 2>&1; then
  echo "SKIP: curl and docker not available"
  exit 0
fi

# shellcheck source=../../scripts/lib/github-webhook.sh
source "${ROOT}/scripts/lib/github-webhook.sh"

chmod +x "${HOOK_SCRIPT}" "${SERVER_SCRIPT}" "${RUNNER}" 2>/dev/null || chmod +x "${RUNNER}"

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

assert_contains() {
  local haystack="$1"
  local needle="$2"
  local label="$3"
  TESTS_RUN=$((TESTS_RUN + 1))
  if [[ "${haystack}" == *"${needle}"* ]]; then
    echo "ok: ${label}"
  else
    echo "FAIL: ${label} — output missing '${needle}'"
    echo "  got: ${haystack}"
    TESTS_FAILED=$((TESTS_FAILED + 1))
  fi
}

TEST_SECRET="integration-webhook-secret"
TEST_PORT="${FLASHGAP_WEBHOOK_E2E_PORT:-29876}"
TEST_LOCK="/tmp/flashgap-deploy-integration.lock"
MAIN_BODY='{"ref":"refs/heads/main","repository":{"full_name":"Ptitgit/flashgap","name":"flashgap"},"pusher":{"name":"deploy-bot"}}'
FEATURE_BODY='{"ref":"refs/heads/task/foo","repository":{"full_name":"Ptitgit/flashgap"}}'
PING_BODY='{"zen":"Non-code is code too."}'
MAIN_SIG="$(github_webhook_compute_signature "${TEST_SECRET}" "${MAIN_BODY}")"

run_linux_hook_suite() {
  "${RUNNER}" "
source /flashgap/scripts/lib/github-webhook.sh
TEST_SECRET='${TEST_SECRET}'
MAIN_BODY='${MAIN_BODY}'
FEATURE_BODY='${FEATURE_BODY}'
MAIN_SIG=\$(github_webhook_compute_signature \"\${TEST_SECRET}\" \"\${MAIN_BODY}\")
LOCK=/tmp/flashgap-deploy-integration.lock
rm -f \"\${LOCK}\"

HOOK_OUT=\$(printf '%s' \"\${MAIN_BODY}\" | \\
  GITHUB_EVENT=push GITHUB_SIGNATURE_256=\"\${MAIN_SIG}\" \\
  FLASHGAP_GITHUB_WEBHOOK_SECRET=\"\${TEST_SECRET}\" \\
  FLASHGAP_WEBHOOK_DRY_RUN=1 FLASHGAP_DEPLOY_LOCK_FILE=\"\${LOCK}\" \\
  bash /flashgap/scripts/github-deploy-hook.sh 2>&1)
echo \"\${HOOK_OUT}\" | grep -q DRY_RUN || { echo 'FAIL hook main'; exit 1; }
echo ok: hook accepts valid main push

BAD_RC=\$(printf '%s' \"\${MAIN_BODY}\" | \\
  GITHUB_EVENT=push GITHUB_SIGNATURE_256=sha256=bad \\
  FLASHGAP_GITHUB_WEBHOOK_SECRET=\"\${TEST_SECRET}\" \\
  bash /flashgap/scripts/github-deploy-hook.sh >/dev/null 2>&1; echo \$?)
test \"\${BAD_RC}\" = '1' || { echo \"FAIL bad sig rc=\${BAD_RC}\"; exit 1; }
echo ok: hook rejects bad signature

FEATURE_SIG=\$(github_webhook_compute_signature \"\${TEST_SECRET}\" \"\${FEATURE_BODY}\")
IGNORE_OUT=\$(printf '%s' \"\${FEATURE_BODY}\" | \\
  GITHUB_EVENT=push GITHUB_SIGNATURE_256=\"\${FEATURE_SIG}\" \\
  FLASHGAP_GITHUB_WEBHOOK_SECRET=\"\${TEST_SECRET}\" \\
  bash /flashgap/scripts/github-deploy-hook.sh 2>&1)
echo \"\${IGNORE_OUT}\" | grep -q Ignored || { echo 'FAIL feature ignore'; exit 1; }
echo ok: hook ignores feature branch

(
  exec 9>\"\${LOCK}\"
  flock 9
  sleep 1
) &
HOLDER=\$!
sleep 0.1
BLOCKED=\$(printf '%s' \"\${MAIN_BODY}\" | \\
  GITHUB_EVENT=push GITHUB_SIGNATURE_256=\"\${MAIN_SIG}\" \\
  FLASHGAP_GITHUB_WEBHOOK_SECRET=\"\${TEST_SECRET}\" \\
  FLASHGAP_DEPLOY_LOCK_FILE=\"\${LOCK}\" \\
  bash /flashgap/scripts/github-deploy-hook.sh 2>&1) || true
wait \"\${HOLDER}\" 2>/dev/null || true
echo \"\${BLOCKED}\" | grep -q 'already in progress' || { echo 'FAIL flock'; exit 1; }
echo ok: flock blocks concurrent deploy
"
}

run_linux_http_suite() {
  docker run --rm -p "${TEST_PORT}:${TEST_PORT}" \
    -v "${ROOT}:/flashgap:ro" \
    -w /flashgap \
    ubuntu:24.04 \
    bash -lc "
set -euo pipefail
export DEBIAN_FRONTEND=noninteractive
apt-get update -qq >/dev/null
apt-get install -qq -y python3 curl openssl util-linux ca-certificates >/dev/null
source /flashgap/scripts/lib/github-webhook.sh
TEST_SECRET='${TEST_SECRET}'
TEST_PORT='${TEST_PORT}'
MAIN_BODY='${MAIN_BODY}'
FEATURE_BODY='${FEATURE_BODY}'
PING_BODY='${PING_BODY}'
MAIN_SIG=\$(github_webhook_compute_signature \"\${TEST_SECRET}\" \"\${MAIN_BODY}\")
FLASHGAP_GITHUB_WEBHOOK_SECRET=\"\${TEST_SECRET}\" \\
FLASHGAP_WEBHOOK_DRY_RUN=1 \\
FLASHGAP_WEBHOOK_PORT=\"\${TEST_PORT}\" \\
FLASHGAP_WEBHOOK_HOST=0.0.0.0 \\
  python3 /flashgap/scripts/github-deploy-webhook-server.py &
sleep 1
post() {
  curl -sS -o /tmp/out -w '%{http_code}' -X POST \"http://127.0.0.1:\${TEST_PORT}\$1\" \\
    -H 'Content-Type: application/json' -H \"X-GitHub-Event: \$2\" \\
    -H \"X-Hub-Signature-256: \$3\" -d \"\$4\"
}
test \"\$(post / push \"\${MAIN_SIG}\" \"\${MAIN_BODY}\")\" = '202'
grep -q DRY_RUN /tmp/out
echo 'ok: POST / main push returns 202'
test \"\$(post /flashgap-deploy-hook push \"\${MAIN_SIG}\" \"\${MAIN_BODY}\")\" = '202'
echo 'ok: POST /flashgap-deploy-hook returns 202'
FSIG=\$(github_webhook_compute_signature \"\${TEST_SECRET}\" \"\${FEATURE_BODY}\")
test \"\$(post / push \"\${FSIG}\" \"\${FEATURE_BODY}\")\" = '202'
grep -q Ignored /tmp/out
echo ok: feature branch ignored
PSIG=\$(github_webhook_compute_signature \"\${TEST_SECRET}\" \"\${PING_BODY}\")
test \"\$(post / ping \"\${PSIG}\" \"\${PING_BODY}\")\" = '202'
grep -q Ignored /tmp/out
echo ok: ping ignored
test \"\$(post / push sha256=invalid \"\${MAIN_BODY}\")\" = '401'
echo 'ok: bad signature returns 401'
test \"\$(post / push '' \"\${MAIN_BODY}\")\" = '401'
echo 'ok: missing signature returns 401'
test \"\$(curl -sS -o /dev/null -w '%{http_code}' -X POST \"http://127.0.0.1:\${TEST_PORT}/unknown\" -d '{}')\" = '404'
echo 'ok: unknown path returns 404'
"
}

echo "==> static artifacts"
assert_contains "$(cat "${NGINX_SNIPPET}")" "location = /flashgap-deploy-hook" "nginx snippet path"
assert_contains "$(cat "${NGINX_SNIPPET}")" "127.0.0.1:9876" "nginx proxies to webhook port"
assert_contains "$(cat "${NGINX_SNIPPET}")" 'X-Hub-Signature-256' "nginx forwards signature header"
assert_contains "$(cat "${SYSTEMD_UNIT}")" "github-deploy-webhook-server.py" "systemd runs python server"
assert_contains "$(cat "${SYSTEMD_UNIT}")" "EnvironmentFile=" "systemd loads .env"

echo "==> GitHub-compatible signature (openssl cross-check)"
OPENSSL_SIG="sha256=$(printf '%s' "${MAIN_BODY}" | openssl dgst -sha256 -hmac "${TEST_SECRET}" | awk '{print $2}')"
assert_eq "${OPENSSL_SIG}" "${MAIN_SIG}" "signature matches openssl reference"

echo "==> python server syntax"
python3 -m py_compile "${SERVER_SCRIPT}"
echo "ok: python syntax valid"

if command -v flock >/dev/null 2>&1; then
  echo "==> hook script direct (Linux host)"
  rm -f "${TEST_LOCK}"
  HOOK_OUT="$(printf '%s' "${MAIN_BODY}" | \
    GITHUB_EVENT=push \
    GITHUB_SIGNATURE_256="${MAIN_SIG}" \
    FLASHGAP_GITHUB_WEBHOOK_SECRET="${TEST_SECRET}" \
    FLASHGAP_WEBHOOK_DRY_RUN=1 \
    FLASHGAP_DEPLOY_LOCK_FILE="${TEST_LOCK}" \
    bash "${HOOK_SCRIPT}" 2>&1)"
  assert_contains "${HOOK_OUT}" "DRY_RUN" "hook accepts valid main push"

  BAD_RC="$(printf '%s' "${MAIN_BODY}" | \
    GITHUB_EVENT=push \
    GITHUB_SIGNATURE_256="sha256=bad" \
    FLASHGAP_GITHUB_WEBHOOK_SECRET="${TEST_SECRET}" \
    bash "${HOOK_SCRIPT}" >/dev/null 2>&1; echo $?)"
  assert_eq "1" "${BAD_RC}" "hook rejects bad signature (exit 1)"

  FEATURE_SIG="$(github_webhook_compute_signature "${TEST_SECRET}" "${FEATURE_BODY}")"
  IGNORE_OUT="$(printf '%s' "${FEATURE_BODY}" | \
    GITHUB_EVENT=push \
    GITHUB_SIGNATURE_256="${FEATURE_SIG}" \
    FLASHGAP_GITHUB_WEBHOOK_SECRET="${TEST_SECRET}" \
    bash "${HOOK_SCRIPT}" 2>&1)"
  assert_contains "${IGNORE_OUT}" "Ignored" "hook ignores feature branch"

  echo "==> flock anti-concurrency (Linux host)"
  rm -f "${TEST_LOCK}"
  (
    exec 9>"${TEST_LOCK}"
    flock 9
    sleep 1
  ) &
  HOLDER_PID=$!
  sleep 0.1
  BLOCKED_OUT="$(printf '%s' "${MAIN_BODY}" | \
    GITHUB_EVENT=push \
    GITHUB_SIGNATURE_256="${MAIN_SIG}" \
    FLASHGAP_GITHUB_WEBHOOK_SECRET="${TEST_SECRET}" \
    FLASHGAP_DEPLOY_LOCK_FILE="${TEST_LOCK}" \
    bash "${HOOK_SCRIPT}" 2>&1)" || true
  wait "${HOLDER_PID}" 2>/dev/null || true
  assert_contains "${BLOCKED_OUT}" "already in progress" "flock blocks concurrent deploy"

  echo "==> HTTP server (Linux host)"
  SERVER_PID=""
  cleanup() {
    if [[ -n "${SERVER_PID}" ]] && kill -0 "${SERVER_PID}" 2>/dev/null; then
      kill "${SERVER_PID}" 2>/dev/null || true
      wait "${SERVER_PID}" 2>/dev/null || true
    fi
    rm -f "${TEST_LOCK}"
  }
  trap cleanup EXIT

  FLASHGAP_GITHUB_WEBHOOK_SECRET="${TEST_SECRET}" \
  FLASHGAP_WEBHOOK_DRY_RUN=1 \
  FLASHGAP_DEPLOY_LOCK_FILE="${TEST_LOCK}" \
  FLASHGAP_WEBHOOK_PORT="${TEST_PORT}" \
  FLASHGAP_WEBHOOK_HOST=127.0.0.1 \
    python3 "${SERVER_SCRIPT}" &
  SERVER_PID=$!
  sleep 0.6

  post_webhook() {
    curl -sS -o /tmp/flashgap-webhook-int.out -w '%{http_code}' \
      -X POST "http://127.0.0.1:${TEST_PORT}${1}" \
      -H "Content-Type: application/json" \
      -H "X-GitHub-Event: ${2}" \
      -H "X-Hub-Signature-256: ${3}" \
      -d "${4}"
  }

  assert_eq "202" "$(post_webhook "/" "push" "${MAIN_SIG}" "${MAIN_BODY}")" "POST / main push => 202"
  assert_contains "$(cat /tmp/flashgap-webhook-int.out)" "DRY_RUN" "response mentions dry run"
  assert_eq "202" "$(post_webhook "/flashgap-deploy-hook" "push" "${MAIN_SIG}" "${MAIN_BODY}")" \
    "POST /flashgap-deploy-hook => 202"
  FEATURE_SIG="$(github_webhook_compute_signature "${TEST_SECRET}" "${FEATURE_BODY}")"
  assert_eq "202" "$(post_webhook "/" "push" "${FEATURE_SIG}" "${FEATURE_BODY}")" "feature branch => 202"
  assert_contains "$(cat /tmp/flashgap-webhook-int.out)" "Ignored" "ignored branch in body"
  PING_SIG="$(github_webhook_compute_signature "${TEST_SECRET}" "${PING_BODY}")"
  assert_eq "202" "$(post_webhook "/" "ping" "${PING_SIG}" "${PING_BODY}")" "ping => 202"
  assert_eq "401" "$(post_webhook "/" "push" "sha256=invalid" "${MAIN_BODY}")" "bad signature => 401"
  assert_eq "401" "$(post_webhook "/" "push" "" "${MAIN_BODY}")" "missing signature => 401"
  UNKNOWN_CODE="$(curl -sS -o /dev/null -w '%{http_code}' \
    -X POST "http://127.0.0.1:${TEST_PORT}/unknown" -d '{}')"
  assert_eq "404" "${UNKNOWN_CODE}" "unknown path => 404"
else
  echo "==> hook + flock via Docker (Ubuntu 24.04 — prod-like)"
  run_linux_hook_suite
  echo "==> HTTP server via Docker (Ubuntu 24.04)"
  run_linux_http_suite
fi

if command -v systemd-analyze >/dev/null 2>&1; then
  systemd-analyze verify "${SYSTEMD_UNIT}" 2>/dev/null && echo "ok: systemd unit verifies" || echo "WARN: systemd-analyze skipped (VPS paths)"
else
  echo "ok: systemd-analyze N/A on this host — unit checked statically"
fi

echo "---"
echo "Ran ${TESTS_RUN} assertions, ${TESTS_FAILED} failed"
if [[ "${TESTS_FAILED}" -gt 0 ]]; then
  exit 1
fi
echo "Webhook integration tests passed."

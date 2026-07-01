#!/usr/bin/env bash
# E2E: start webhook server locally, POST signed payload, assert HTTP responses.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
RUNNER="${ROOT}/tests/lib/webhook-linux-runner.sh"
HOOK_SCRIPT="${ROOT}/scripts/github-deploy-hook.sh"
SERVER_SCRIPT="${ROOT}/scripts/github-deploy-webhook-server.py"
# shellcheck source=../../scripts/lib/github-webhook.sh
source "${ROOT}/scripts/lib/github-webhook.sh"

if ! command -v python3 >/dev/null 2>&1 && ! command -v docker >/dev/null 2>&1; then
  echo "SKIP: python3 and docker not available"
  exit 0
fi

if ! command -v curl >/dev/null 2>&1 && ! command -v docker >/dev/null 2>&1; then
  echo "SKIP: curl and docker not available"
  exit 0
fi

run_e2e() {
  local test_secret="e2e-webhook-secret"
  local test_port="${FLASHGAP_WEBHOOK_E2E_PORT:-19876}"
  local test_body='{"ref":"refs/heads/main","repository":{"full_name":"Ptitgit/flashgap"}}'
  local sig
  sig="$(github_webhook_compute_signature "${test_secret}" "${test_body}")"

  chmod +x "${HOOK_SCRIPT}" "${SERVER_SCRIPT}"

  local server_pid=""
  cleanup() {
    if [[ -n "${server_pid}" ]] && kill -0 "${server_pid}" 2>/dev/null; then
      kill "${server_pid}" 2>/dev/null || true
      wait "${server_pid}" 2>/dev/null || true
    fi
  }
  trap cleanup EXIT

  FLASHGAP_GITHUB_WEBHOOK_SECRET="${test_secret}" \
  FLASHGAP_WEBHOOK_DRY_RUN=1 \
  FLASHGAP_WEBHOOK_PORT="${test_port}" \
  FLASHGAP_WEBHOOK_HOST=127.0.0.1 \
    python3 "${SERVER_SCRIPT}" &
  server_pid=$!

  sleep 0.5

  local http_code
  http_code="$(curl -sS -o /tmp/flashgap-webhook-e2e.out -w '%{http_code}' \
    -X POST "http://127.0.0.1:${test_port}/" \
    -H "Content-Type: application/json" \
    -H "X-GitHub-Event: push" \
    -H "X-Hub-Signature-256: ${sig}" \
    -d "${test_body}")"

  if [[ "${http_code}" != "202" ]]; then
    echo "FAIL: expected HTTP 202 for valid signature, got ${http_code}"
    cat /tmp/flashgap-webhook-e2e.out || true
    exit 1
  fi
  echo "ok: valid signature returns 202"

  local bad_code
  bad_code="$(curl -sS -o /tmp/flashgap-webhook-e2e-bad.out -w '%{http_code}' \
    -X POST "http://127.0.0.1:${test_port}/" \
    -H "Content-Type: application/json" \
    -H "X-GitHub-Event: push" \
    -H "X-Hub-Signature-256: sha256=deadbeef" \
    -d "${test_body}")"

  if [[ "${bad_code}" != "401" ]]; then
    echo "FAIL: expected HTTP 401 for bad signature, got ${bad_code}"
    cat /tmp/flashgap-webhook-e2e-bad.out || true
    exit 1
  fi
  echo "ok: bad signature returns 401"
}

if command -v flock >/dev/null 2>&1; then
  run_e2e
else
  echo "==> e2e webhook via Docker (host lacks flock)"
  chmod +x "${RUNNER}"
  "${RUNNER}" "
source /flashgap/scripts/lib/github-webhook.sh
TEST_SECRET=e2e-webhook-secret
TEST_PORT=${FLASHGAP_WEBHOOK_E2E_PORT:-19876}
TEST_BODY='{\"ref\":\"refs/heads/main\",\"repository\":{\"full_name\":\"Ptitgit/flashgap\"}}'
SIG=\$(github_webhook_compute_signature \"\${TEST_SECRET}\" \"\${TEST_BODY}\")
FLASHGAP_GITHUB_WEBHOOK_SECRET=\"\${TEST_SECRET}\" \\
FLASHGAP_WEBHOOK_DRY_RUN=1 \\
FLASHGAP_WEBHOOK_PORT=\"\${TEST_PORT}\" \\
FLASHGAP_WEBHOOK_HOST=0.0.0.0 \\
  python3 /flashgap/scripts/github-deploy-webhook-server.py &
SERVER_PID=\$!
sleep 1
HTTP=\$(curl -sS -o /tmp/out -w '%{http_code}' -X POST \"http://127.0.0.1:\${TEST_PORT}/\" \\
  -H 'Content-Type: application/json' -H 'X-GitHub-Event: push' \\
  -H \"X-Hub-Signature-256: \${SIG}\" -d \"\${TEST_BODY}\")
test \"\${HTTP}\" = '202' || { echo FAIL valid sig; exit 1; }
echo 'ok: valid signature returns 202'
BAD=\$(curl -sS -o /tmp/out -w '%{http_code}' -X POST \"http://127.0.0.1:\${TEST_PORT}/\" \\
  -H 'Content-Type: application/json' -H 'X-GitHub-Event: push' \\
  -H 'X-Hub-Signature-256: sha256=deadbeef' -d \"\${TEST_BODY}\")
test \"\${BAD}\" = '401' || { echo FAIL bad sig; exit 1; }
echo 'ok: bad signature returns 401'
kill \"\${SERVER_PID}\" 2>/dev/null || true
"
fi

echo "Webhook e2e passed."

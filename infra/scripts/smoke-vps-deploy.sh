#!/usr/bin/env bash
# Smoke test: validates Flashgap deploy on a provisioned VPS (run from dev machine via SSH).
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
FLASHGAP_PUBLIC_HOSTNAME="${FLASHGAP_PUBLIC_HOSTNAME:-}"
FLASHGAP_API_HOST_PORT="${FLASHGAP_API_HOST_PORT:-3010}"
FLASHGAP_HEALTH_URL="${FLASHGAP_HEALTH_URL:-}"

FAILURES=0

fail() {
  echo "FAIL: $*" >&2
  FAILURES=$((FAILURES + 1))
}

pass() {
  echo "ok: $*"
}

ssh_cmd() {
  ssh -o BatchMode=yes -o ConnectTimeout=15 -p "${FLASHGAP_SSH_PORT}" \
    "${FLASHGAP_SSH_USER}@${FLASHGAP_SSH_HOST}" "$@"
}

require_env FLASHGAP_SSH_HOST || exit 1

if [[ -z "${FLASHGAP_HEALTH_URL}" ]]; then
  if [[ -z "${FLASHGAP_PUBLIC_HOSTNAME}" ]]; then
    fail "FLASHGAP_HEALTH_URL or FLASHGAP_PUBLIC_HOSTNAME must be set"
    exit 1
  fi
  FLASHGAP_HEALTH_URL="https://${FLASHGAP_PUBLIC_HOSTNAME}/flashgap/health"
fi

INFRA_DIR="/home/${FLASHGAP_SSH_USER}/flashgap/infra"
COMPOSE_CMD="docker compose -f docker-compose.yml -f docker-compose.nginx-vps.yml --env-file .env"

echo "Smoke VPS deploy — ${FLASHGAP_SSH_USER}@${FLASHGAP_SSH_HOST}"

if ssh_cmd "test -x ${INFRA_DIR}/scripts/deploy.sh"; then
  pass "deploy.sh present and executable"
else
  fail "missing ${INFRA_DIR}/scripts/deploy.sh"
fi

if ssh_cmd "test -f ${INFRA_DIR}/.env"; then
  pass ".env configured"
else
  fail "missing ${INFRA_DIR}/.env"
fi

PS_OUTPUT="$(ssh_cmd "cd ${INFRA_DIR} && ${COMPOSE_CMD} ps" 2>/dev/null || true)"
if echo "${PS_OUTPUT}" | grep -q 'api'; then
  pass "docker compose ps lists api"
else
  fail "api container not running"
fi

if echo "${PS_OUTPUT}" | grep -q '(healthy)'; then
  pass "at least one service healthy"
else
  fail "no healthy service in compose ps"
fi

if ssh_cmd "curl -fsS http://127.0.0.1:${FLASHGAP_API_HOST_PORT}/health" | grep -q '"ok"'; then
  pass "local API /health on 127.0.0.1:${FLASHGAP_API_HOST_PORT}"
else
  fail "local API /health failed on port ${FLASHGAP_API_HOST_PORT}"
fi

if curl -fsS --max-time 15 "${FLASHGAP_HEALTH_URL}" | grep -q '"ok"'; then
  pass "public HTTPS ${FLASHGAP_HEALTH_URL}"
else
  fail "public HTTPS health check failed: ${FLASHGAP_HEALTH_URL}"
fi

if ssh_cmd "cd ${INFRA_DIR} && ${COMPOSE_CMD} logs --tail=5 api" | grep -qiE 'listening|started|ready|server'; then
  pass "api logs accessible (docker compose logs api)"
else
  # API may log minimally — container healthy is enough if logs empty
  if echo "${PS_OUTPUT}" | grep -q 'api.*healthy'; then
    pass "api logs accessible (healthy container)"
  else
    fail "cannot read api logs and api not healthy"
  fi
fi

echo "---"
if [[ "${FAILURES}" -gt 0 ]]; then
  echo "${FAILURES} check(s) failed"
  exit 1
fi
echo "All smoke deploy checks passed (${FLASHGAP_HEALTH_URL})"

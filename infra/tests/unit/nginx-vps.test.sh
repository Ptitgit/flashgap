#!/usr/bin/env bash
# Unit tests for nginx VPS compose overlay (prod default — no stack up)
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
COMPOSE_BASE="${ROOT}/docker-compose.yml"
COMPOSE_NGINX="${ROOT}/docker-compose.nginx-vps.yml"
NGINX_SNIPPET="${ROOT}/scripts/nginx-flashgap.conf"
ENV_FILE="${ROOT}/.env.example"

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

assert_api_binds_localhost() {
  docker compose -f "${COMPOSE_BASE}" -f "${COMPOSE_NGINX}" --env-file "${ENV_FILE}" config 2>/dev/null |
    grep -qE 'published: "3010"|127\.0\.0\.1:3010:3000'
}

if ! command -v docker >/dev/null 2>&1; then
  echo "SKIP: docker not installed"
  exit 0
fi

echo "==> nginx VPS compose validates"
docker compose -f "${COMPOSE_BASE}" -f "${COMPOSE_NGINX}" --env-file "${ENV_FILE}" config >/dev/null

assert_ok "nginx overlay exists" test -f "${COMPOSE_NGINX}"
assert_ok "nginx snippet exists" test -f "${NGINX_SNIPPET}"
assert_ok "api binds 127.0.0.1:3010" assert_api_binds_localhost
assert_ok "snippet proxies to 3010" grep -q '127.0.0.1:3010' "${NGINX_SNIPPET}"
assert_ok "snippet uses /flashgap/ path" grep -q '/flashgap/' "${NGINX_SNIPPET}"
assert_ok "deploy defaults to nginx" grep -q 'docker-compose.nginx-vps.yml' "${ROOT}/scripts/deploy.sh"

echo "---"
echo "Ran ${TESTS_RUN} assertions, ${TESTS_FAILED} failed"
if [[ "${TESTS_FAILED}" -gt 0 ]]; then
  exit 1
fi

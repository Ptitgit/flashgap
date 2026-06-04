#!/usr/bin/env bash
# Unit tests for HTTPS reverse proxy (compose config + Caddyfile render — no stack up)
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
COMPOSE_FILE="${ROOT}/docker-compose.yml"
ENV_FILE="${ROOT}/.env.example"
RENDER_SCRIPT="${ROOT}/scripts/render-caddyfile.sh"

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

assert_service_listed() {
  local name="$1"
  docker compose -f "${COMPOSE_FILE}" --env-file "${ENV_FILE}" config --services 2>/dev/null |
    grep -qx "${name}"
}

assert_service_has_no_published_ports() {
  local name="$1"
  ! docker compose -f "${COMPOSE_FILE}" --env-file "${ENV_FILE}" config 2>/dev/null |
    awk -v svc="${name}" '
      $0 ~ "^  " svc ":" { in_svc=1; next }
      in_svc && /^  [a-z0-9_-]+:/ { in_svc=0 }
      in_svc && /^    ports:/ { found=1 }
      END { exit(found ? 0 : 1) }
    '
}

assert_service_publishes_ports() {
  local name="$1"
  docker compose -f "${COMPOSE_FILE}" --env-file "${ENV_FILE}" config 2>/dev/null |
    awk -v svc="${name}" '
      $0 ~ "^  " svc ":" { in_svc=1; next }
      in_svc && /^  [a-z0-9_-]+:/ { in_svc=0 }
      in_svc && /^    ports:/ { found=1 }
      END { exit(found ? 0 : 1) }
    '
}

assert_env_example_has() {
  local key="$1"
  grep -q "^${key}=" "${ENV_FILE}"
}

assert_render_localhost_tls_internal() {
  PUBLIC_HOSTNAME=localhost ACME_EMAIL='' "${RENDER_SCRIPT}" | grep -q 'tls internal'
}

assert_render_prod_uses_acme_email() {
  PUBLIC_HOSTNAME=api.flashgap.example ACME_EMAIL=ops@flashgap.example "${RENDER_SCRIPT}" |
    grep -q 'email ops@flashgap.example'
}

assert_render_prod_no_tls_internal() {
  ! PUBLIC_HOSTNAME=api.flashgap.example ACME_EMAIL=ops@flashgap.example "${RENDER_SCRIPT}" |
    grep -q 'tls internal'
}

if [[ ! -f "${COMPOSE_FILE}" ]]; then
  echo "FAIL: missing ${COMPOSE_FILE}"
  exit 1
fi

if [[ ! -f "${ENV_FILE}" ]]; then
  echo "FAIL: missing ${ENV_FILE}"
  exit 1
fi

if ! command -v docker >/dev/null 2>&1; then
  echo "SKIP: docker not installed"
  exit 0
fi

echo "==> caddy reverse proxy config validates"
docker compose -f "${COMPOSE_FILE}" --env-file "${ENV_FILE}" config >/dev/null

assert_ok "PUBLIC_HOSTNAME in .env.example" assert_env_example_has PUBLIC_HOSTNAME
assert_ok "ACME_EMAIL in .env.example" assert_env_example_has ACME_EMAIL
assert_ok "render script exists" test -x "${RENDER_SCRIPT}"
assert_ok "service caddy" assert_service_listed caddy
assert_ok "caddy publishes host ports" assert_service_publishes_ports caddy
assert_ok "api not published to host" assert_service_has_no_published_ports api
assert_ok "postgres not published to host" assert_service_has_no_published_ports postgres
assert_ok "minio not published to host" assert_service_has_no_published_ports minio
assert_ok "localhost render uses tls internal" assert_render_localhost_tls_internal
assert_ok "prod render sets ACME email" assert_render_prod_uses_acme_email
assert_ok "prod render without tls internal" assert_render_prod_no_tls_internal

echo "---"
echo "Ran ${TESTS_RUN} assertions, ${TESTS_FAILED} failed"
if [[ "${TESTS_FAILED}" -gt 0 ]]; then
  exit 1
fi

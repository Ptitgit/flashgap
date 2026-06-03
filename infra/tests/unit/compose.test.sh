#!/usr/bin/env bash
# Unit tests for infra/docker-compose.yml (TDD — docker compose config, no stack up)
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
COMPOSE_FILE="${ROOT}/docker-compose.yml"
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

assert_service_has_volume() {
  local name="$1"
  docker compose -f "${COMPOSE_FILE}" --env-file "${ENV_FILE}" config 2>/dev/null |
    awk -v svc="${name}" '
      $0 ~ "^  " svc ":" { in_svc=1; next }
      in_svc && /^  [a-z0-9_-]+:/ { in_svc=0 }
      in_svc && /^    volumes:/ { found=1 }
      END { exit(found ? 0 : 1) }
    '
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

echo "==> compose config validates"
docker compose -f "${COMPOSE_FILE}" --env-file "${ENV_FILE}" config >/dev/null

assert_ok "service postgres" assert_service_listed postgres
assert_ok "service minio" assert_service_listed minio
assert_ok "service api" assert_service_listed api

assert_ok "postgres has persistent volume" assert_service_has_volume postgres
assert_ok "minio has persistent volume" assert_service_has_volume minio

assert_ok "postgres not published to host" assert_service_has_no_published_ports postgres
assert_ok "minio not published to host" assert_service_has_no_published_ports minio

echo "---"
echo "Ran ${TESTS_RUN} assertions, ${TESTS_FAILED} failed"
if [[ "${TESTS_FAILED}" -gt 0 ]]; then
  exit 1
fi

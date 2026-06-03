#!/usr/bin/env bash
# Unit tests for MinIO private bucket setup (compose config + env — no stack up)
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
COMPOSE_FILE="${ROOT}/docker-compose.yml"
ENV_FILE="${ROOT}/.env.example"
INIT_SCRIPT="${ROOT}/scripts/minio-init-bucket.sh"

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

assert_env_example_has() {
  local key="$1"
  grep -q "^${key}=" "${ENV_FILE}"
}

assert_compose_api_has_env() {
  local key="$1"
  docker compose -f "${COMPOSE_FILE}" --env-file "${ENV_FILE}" config 2>/dev/null |
    awk -v key="${key}" '
      $0 ~ /^  api:/ { in_api=1; next }
      in_api && /^  [a-z0-9_-]+:/ { in_api=0 }
      in_api && $0 ~ key { found=1 }
      END { exit(found ? 0 : 1) }
    '
}

assert_init_script_sets_private_policy() {
  grep -q 'mc anonymous set none' "${INIT_SCRIPT}"
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

echo "==> minio bucket config validates"
docker compose -f "${COMPOSE_FILE}" --env-file "${ENV_FILE}" config >/dev/null

assert_ok "MINIO_BUCKET in .env.example" assert_env_example_has MINIO_BUCKET
assert_ok "minio-init service defined" assert_service_listed minio-init
assert_ok "init script exists" test -f "${INIT_SCRIPT}"
assert_ok "init script denies anonymous access" assert_init_script_sets_private_policy
assert_ok "api receives MINIO_BUCKET" assert_compose_api_has_env MINIO_BUCKET

echo "---"
echo "Ran ${TESTS_RUN} assertions, ${TESTS_FAILED} failed"
if [[ "${TESTS_FAILED}" -gt 0 ]]; then
  exit 1
fi

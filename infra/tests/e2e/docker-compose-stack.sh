#!/usr/bin/env bash
# E2E: docker compose up — curl /health — tear down (optional, needs Docker)
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
COMPOSE_FILE="${ROOT}/docker-compose.yml"
ENV_FILE="${ROOT}/.env.example"
PROJECT="flashgap-compose-e2e-$$"
HTTPS_PORT="${FLASHGAP_COMPOSE_E2E_HTTPS_PORT:-3443}"
HTTP_PORT="${FLASHGAP_COMPOSE_E2E_HTTP_PORT:-3180}"

if ! command -v docker >/dev/null 2>&1; then
  echo "SKIP: docker not installed"
  exit 0
fi

cleanup() {
  docker compose -f "${COMPOSE_FILE}" --env-file "${ENV_FILE}" \
    -p "${PROJECT}" down -v --remove-orphans >/dev/null 2>&1 || true
}
trap cleanup EXIT

export HTTPS_PORT HTTP_PORT PUBLIC_HOSTNAME=localhost

echo "==> compose build & up (${PROJECT})"
docker compose -f "${COMPOSE_FILE}" --env-file "${ENV_FILE}" \
  -p "${PROJECT}" up -d --build --wait

echo "==> curl /health"
for _ in $(seq 1 30); do
  if curl -kfsS --resolve "localhost:${HTTPS_PORT}:127.0.0.1" \
    "https://localhost:${HTTPS_PORT}/health" | grep -q '"ok"'; then
    echo "E2E docker compose stack: ok"
    exit 0
  fi
  sleep 2
done

echo "FAIL: /health not ready on https://localhost:${HTTPS_PORT}"
docker compose -f "${COMPOSE_FILE}" --env-file "${ENV_FILE}" -p "${PROJECT}" ps
exit 1

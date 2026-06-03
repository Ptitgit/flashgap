#!/usr/bin/env bash
# E2E: docker compose up — curl /health — tear down (optional, needs Docker)
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
COMPOSE_FILE="${ROOT}/docker-compose.yml"
ENV_FILE="${ROOT}/.env.example"
PROJECT="flashgap-compose-e2e-$$"
API_PORT="${FLASHGAP_COMPOSE_E2E_API_PORT:-3100}"

if ! command -v docker >/dev/null 2>&1; then
  echo "SKIP: docker not installed"
  exit 0
fi

cleanup() {
  docker compose -f "${COMPOSE_FILE}" --env-file "${ENV_FILE}" \
    -p "${PROJECT}" down -v --remove-orphans >/dev/null 2>&1 || true
}
trap cleanup EXIT

export API_PORT

echo "==> compose build & up (${PROJECT})"
docker compose -f "${COMPOSE_FILE}" --env-file "${ENV_FILE}" \
  -p "${PROJECT}" up -d --build --wait

echo "==> curl /health"
for _ in $(seq 1 30); do
  if curl -fsS "http://127.0.0.1:${API_PORT}/health" | grep -q '"ok"'; then
    echo "E2E docker compose stack: ok"
    exit 0
  fi
  sleep 2
done

echo "FAIL: /health not ready on port ${API_PORT}"
docker compose -f "${COMPOSE_FILE}" --env-file "${ENV_FILE}" -p "${PROJECT}" ps
exit 1

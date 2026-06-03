#!/usr/bin/env bash
# Smoke: stack Compose locale (nécessite infra/.env ou .env.example)
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
COMPOSE_FILE="${ROOT}/docker-compose.yml"

ENV_FILE="${ROOT}/.env"
if [[ ! -f "${ENV_FILE}" ]]; then
  ENV_FILE="${ROOT}/.env.example"
fi

set -a
# shellcheck disable=SC1090,SC1091
source "${ENV_FILE}"
set +a
API_PORT="${API_PORT:-3005}"

require_cmd() {
  command -v "$1" >/dev/null 2>&1 || {
    echo "ERROR: missing command: $1" >&2
    exit 1
  }
}

require_cmd docker
require_cmd curl

echo "==> docker compose ps"
docker compose -f "${COMPOSE_FILE}" --env-file "${ENV_FILE}" ps

echo "==> GET /health"
body="$(curl -fsS "http://127.0.0.1:${API_PORT}/health")"
if ! grep -q '"status":"ok"' <<<"${body}" && ! grep -q '"status": "ok"' <<<"${body}"; then
  echo "FAIL: unexpected /health body: ${body}" >&2
  exit 1
fi

echo "Smoke compose stack: ok"

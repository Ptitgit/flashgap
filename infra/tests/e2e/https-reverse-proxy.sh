#!/usr/bin/env bash
# E2E: Caddy terminates TLS — GET /health over HTTPS, HTTP redirects to HTTPS
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
COMPOSE_FILE="${ROOT}/docker-compose.yml"
COMPOSE_CADDY="${ROOT}/docker-compose.caddy.yml"
ENV_FILE="${ROOT}/.env.example"
PROJECT="flashgap-https-e2e-$$"
HTTP_PORT="${FLASHGAP_HTTPS_E2E_HTTP_PORT:-3180}"
HTTPS_PORT="${FLASHGAP_HTTPS_E2E_HTTPS_PORT:-3443}"

if ! command -v docker >/dev/null 2>&1; then
  echo "SKIP: docker not installed"
  exit 0
fi

cleanup() {
  docker compose -f "${COMPOSE_FILE}" -f "${COMPOSE_CADDY}" --env-file "${ENV_FILE}" \
    -p "${PROJECT}" down -v --remove-orphans >/dev/null 2>&1 || true
}
trap cleanup EXIT

export PUBLIC_HOSTNAME=localhost
export HTTP_PORT
export HTTPS_PORT

echo "==> compose up caddy + api (${PROJECT})"
docker compose -f "${COMPOSE_FILE}" -f "${COMPOSE_CADDY}" --env-file "${ENV_FILE}" \
  -p "${PROJECT}" up -d --build --wait

echo "==> GET /health over HTTPS"
for _ in $(seq 1 30); do
  if curl -kfsS --resolve "localhost:${HTTPS_PORT}:127.0.0.1" \
    "https://localhost:${HTTPS_PORT}/health" | grep -q '"ok"'; then
    break
  fi
  sleep 2
done
if ! curl -kfsS --resolve "localhost:${HTTPS_PORT}:127.0.0.1" \
  "https://localhost:${HTTPS_PORT}/health" | grep -q '"ok"'; then
  echo "FAIL: /health not ready on https://localhost:${HTTPS_PORT}"
  docker compose -f "${COMPOSE_FILE}" -f "${COMPOSE_CADDY}" --env-file "${ENV_FILE}" -p "${PROJECT}" ps
  exit 1
fi

echo "==> HTTP redirects to HTTPS"
location="$(curl -sI --resolve "localhost:${HTTP_PORT}:127.0.0.1" \
  "http://localhost:${HTTP_PORT}/health" | tr -d '\r' | awk -F': ' '/^Location:/ { print $2; exit }')"
if [[ -z "${location}" ]]; then
  echo "FAIL: no Location header on HTTP /health" >&2
  exit 1
fi
case "${location}" in
  https://*) ;;
  *)
    echo "FAIL: expected https redirect, got: ${location}" >&2
    exit 1
    ;;
esac

echo "E2E HTTPS reverse proxy: ok"

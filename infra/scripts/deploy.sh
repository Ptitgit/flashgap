#!/usr/bin/env bash
# Redeploy Flashgap stack on VPS (run as deploy from repo clone under infra/).
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
COMPOSE_BASE="${ROOT}/docker-compose.yml"
COMPOSE_NGINX="${ROOT}/docker-compose.nginx-vps.yml"
COMPOSE_CADDY="${ROOT}/docker-compose.caddy.yml"
ENV_FILE="${ROOT}/.env"

usage() {
  cat <<'EOF'
Usage: deploy.sh [--skip-git-pull] [--with-caddy]

Default (prod VPS with nginx on 80/443):
  API on 127.0.0.1:${FLASHGAP_API_HOST_PORT:-3010} — configure nginx (see scripts/nginx-flashgap.conf)

Optional local / dedicated VPS with Caddy instead of nginx:
  deploy.sh --with-caddy

API logs:
  docker compose --env-file .env logs -f api
EOF
}

SKIP_GIT=0
WITH_CADDY=0
for arg in "$@"; do
  case "${arg}" in
    --skip-git-pull) SKIP_GIT=1 ;;
    --with-caddy) WITH_CADDY=1 ;;
    --shared-vps)
      echo "NOTE: --shared-vps is deprecated (nginx is now the default)." >&2
      ;;
    -h | --help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown option: ${arg}" >&2
      usage >&2
      exit 1
      ;;
  esac
done

require_cmd() {
  command -v "$1" >/dev/null 2>&1 || {
    echo "ERROR: missing command: $1" >&2
    exit 1
  }
}

if [[ ! -f "${ENV_FILE}" ]]; then
  echo "ERROR: missing ${ENV_FILE} — cp .env.example .env and configure secrets." >&2
  exit 1
fi

require_cmd docker

cd "${ROOT}"

if [[ "${SKIP_GIT}" -eq 0 ]]; then
  require_cmd git
  echo "==> git pull"
  git -C "${ROOT}/.." pull --ff-only
fi

COMPOSE_ARGS=(-f "${COMPOSE_BASE}" --env-file "${ENV_FILE}")
if [[ "${WITH_CADDY}" -eq 1 ]]; then
  COMPOSE_ARGS+=(-f "${COMPOSE_CADDY}")
  echo "==> Caddy mode (dev / VPS dédié sans nginx)"
else
  COMPOSE_ARGS+=(-f "${COMPOSE_NGINX}")
  echo "==> nginx VPS mode: API on 127.0.0.1:\${FLASHGAP_API_HOST_PORT:-3010}"
fi

echo "==> docker compose up -d --build"
docker compose "${COMPOSE_ARGS[@]}" up -d --build

echo "==> docker compose ps"
docker compose "${COMPOSE_ARGS[@]}" ps

echo "Deploy complete."
if [[ "${WITH_CADDY}" -eq 0 ]]; then
  echo "Configure nginx: see ${ROOT}/scripts/nginx-flashgap.conf"
fi
echo "Logs: docker compose ${COMPOSE_ARGS[*]} logs -f api"

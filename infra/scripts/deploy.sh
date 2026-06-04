#!/usr/bin/env bash
# Redeploy Flashgap stack on VPS (run as deploy from repo clone under infra/).
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
COMPOSE_FILE="${ROOT}/docker-compose.yml"
ENV_FILE="${ROOT}/.env"

usage() {
  cat <<'EOF'
Usage: deploy.sh [--skip-git-pull]

Pull latest code and rebuild containers:
  git pull && docker compose up -d --build

API logs:
  docker compose --env-file .env logs -f api
EOF
}

SKIP_GIT=0
for arg in "$@"; do
  case "${arg}" in
    --skip-git-pull) SKIP_GIT=1 ;;
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

echo "==> docker compose up -d --build"
docker compose -f "${COMPOSE_FILE}" --env-file "${ENV_FILE}" up -d --build

echo "==> docker compose ps"
docker compose -f "${COMPOSE_FILE}" --env-file "${ENV_FILE}" ps

echo "Deploy complete."
echo "Logs: docker compose -f ${COMPOSE_FILE} --env-file ${ENV_FILE} logs -f api"

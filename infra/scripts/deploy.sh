#!/usr/bin/env bash
# Redeploy Flashgap stack on VPS (E1-US5).
# Usage:
#   deploy.sh [--dry-run]              # git pull + docker compose up -d --build
#   deploy.sh logs [--dry-run] [svc]   # docker compose logs -f (default: api)
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INFRA_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
REPO_ROOT="$(cd "${INFRA_DIR}/.." && pwd)"
COMPOSE_FILE="${INFRA_DIR}/docker-compose.yml"

DRY_RUN=0
SERVICE=api

usage() {
  cat <<'EOF'
Usage:
  deploy.sh [--dry-run]                 Redeploy: git pull, docker compose up -d --build
  deploy.sh logs [--dry-run] [service]  Follow service logs (default: api)

Environment:
  FLASHGAP_INFRA_DIR  Override infra directory (default: sibling of repo scripts/)
EOF
}

run_step() {
  if [[ "${DRY_RUN}" -eq 1 ]]; then
    echo "$*"
    return 0
  fi
  "$@"
}

require_env_file() {
  local env_file="${INFRA_DIR}/.env"
  if [[ ! -f "${env_file}" ]]; then
    echo "ERROR: missing ${env_file} — copy from .env.example and edit secrets." >&2
    exit 1
  fi
  echo "${env_file}"
}

compose() {
  local env_file
  env_file="$(require_env_file)"
  docker compose -f "${COMPOSE_FILE}" --env-file "${env_file}" "$@"
}

cmd_deploy() {
  if [[ -d "${REPO_ROOT}/.git" ]]; then
    (
      cd "${REPO_ROOT}"
      run_step git pull
    )
  elif [[ "${DRY_RUN}" -eq 0 ]]; then
    echo "WARN: ${REPO_ROOT} is not a git repository — skipping git pull" >&2
  else
    echo "git pull"
  fi

  if [[ "${DRY_RUN}" -eq 1 ]]; then
    echo "docker compose up -d --build"
    return 0
  fi

  (
    cd "${INFRA_DIR}"
    compose up -d --build
  )
}

cmd_logs() {
  if [[ "${DRY_RUN}" -eq 1 ]]; then
    echo "docker compose logs -f ${SERVICE}"
    return 0
  fi

  (
    cd "${INFRA_DIR}"
    compose logs -f "${SERVICE}"
  )
}

main() {
  if [[ -n "${FLASHGAP_INFRA_DIR:-}" ]]; then
    INFRA_DIR="$(cd "${FLASHGAP_INFRA_DIR}" && pwd)"
    COMPOSE_FILE="${INFRA_DIR}/docker-compose.yml"
  fi

  local subcmd=deploy
  local positional=()

  for arg in "$@"; do
    case "${arg}" in
      --dry-run)
        DRY_RUN=1
        ;;
      -h | --help)
        usage
        exit 0
        ;;
      deploy | logs)
        subcmd="${arg}"
        ;;
      *)
        positional+=("${arg}")
        ;;
    esac
  done

  if [[ "${subcmd}" == logs && -n "${positional[0]:-}" ]]; then
    SERVICE="${positional[0]}"
  fi

  case "${subcmd}" in
    deploy)
      cmd_deploy
      ;;
    logs)
      cmd_logs
      ;;
    *)
      usage >&2
      exit 1
      ;;
  esac
}

main "$@"

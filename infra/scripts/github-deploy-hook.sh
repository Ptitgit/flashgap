#!/usr/bin/env bash
# Process a GitHub webhook payload (body on stdin) and trigger deploy on push to main.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=lib/github-webhook.sh
source "${ROOT}/scripts/lib/github-webhook.sh"

BODY="$(cat)"
EVENT="${GITHUB_EVENT:-}"
SIG="${GITHUB_SIGNATURE_256:-}"
SECRET="${FLASHGAP_GITHUB_WEBHOOK_SECRET:-}"

if [[ -z "${SECRET}" ]]; then
  echo "ERROR: FLASHGAP_GITHUB_WEBHOOK_SECRET is not set" >&2
  exit 1
fi

if ! github_webhook_verify_signature "${SECRET}" "${SIG}" "${BODY}"; then
  echo "ERROR: invalid webhook signature" >&2
  exit 1
fi

REF="$(github_webhook_extract_ref "${BODY}")"
if ! github_webhook_is_main_push "${EVENT}" "${REF}"; then
  echo "Ignored: event=${EVENT:-<empty>} ref=${REF:-<empty>}"
  exit 0
fi

REPO_ROOT="${FLASHGAP_REPO_ROOT:-${ROOT}/..}"
LOCK_FILE="${FLASHGAP_DEPLOY_LOCK_FILE:-/tmp/flashgap-deploy.lock}"
DEPLOY_SCRIPT="${ROOT}/scripts/deploy.sh"
DRY_RUN="${FLASHGAP_WEBHOOK_DRY_RUN:-0}"

if [[ ! -x "${DEPLOY_SCRIPT}" ]]; then
  echo "ERROR: deploy script not found or not executable: ${DEPLOY_SCRIPT}" >&2
  exit 2
fi

require_cmd() {
  command -v "$1" >/dev/null 2>&1 || {
    echo "ERROR: missing command: $1" >&2
    exit 2
  }
}

require_cmd flock

exec 9>"${LOCK_FILE}"
if ! flock -n 9; then
  echo "Deploy already in progress — skipped"
  exit 0
fi

echo "==> Webhook deploy: git pull + deploy.sh (repo=${REPO_ROOT})"

if [[ "${DRY_RUN}" == "1" ]]; then
  echo "DRY_RUN: would run git pull and ${DEPLOY_SCRIPT} --skip-git-pull"
  exit 0
fi

require_cmd git
git -C "${REPO_ROOT}" pull --ff-only origin main
"${DEPLOY_SCRIPT}" --skip-git-pull

echo "Deploy complete."

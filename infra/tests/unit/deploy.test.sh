#!/usr/bin/env bash
# Unit tests for deploy script and README (no VPS required)
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
DEPLOY_SCRIPT="${ROOT}/scripts/deploy.sh"
README="${ROOT}/README.md"

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

echo "==> deploy script and README"
assert_ok "deploy.sh exists" test -f "${DEPLOY_SCRIPT}"
assert_ok "deploy.sh executable" test -x "${DEPLOY_SCRIPT}"
assert_ok "deploy runs git pull" grep -q 'git pull' "${DEPLOY_SCRIPT}"
assert_ok "deploy runs compose up --build" grep -qE 'compose.*up -d --build' "${DEPLOY_SCRIPT}"
assert_ok "deploy documents api logs" grep -qE 'logs -f api' "${DEPLOY_SCRIPT}"
assert_ok "deploy supports optional Caddy" grep -q '\-\-with-caddy' "${DEPLOY_SCRIPT}"
assert_ok "nginx VPS compose overlay exists" test -f "${ROOT}/docker-compose.nginx-vps.yml"
assert_ok "nginx snippet exists" test -f "${ROOT}/scripts/nginx-flashgap.conf"
assert_ok "README has Deploy section" grep -qE '^## (Déploiement|Deploy)' "${README}"
assert_ok "README documents git pull" grep -q 'git pull' "${README}"
assert_ok "README documents compose up --build" grep -q 'docker compose' "${README}" &&
  grep -q 'up -d --build' "${README}"
assert_ok "README documents api logs" grep -qE 'logs -f api' "${README}"
assert_ok "README documents first deploy clone" grep -qiE 'git clone|premier déploiement|first deploy' "${README}"
assert_ok "README documents .env setup" grep -qE '\.env\.example|\.env' "${README}"
assert_ok "README documents shared VPS" grep -q 'nginx' "${README}" &&
  grep -q '3010' "${README}"

echo "---"
echo "Ran ${TESTS_RUN} assertions, ${TESTS_FAILED} failed"
if [[ "${TESTS_FAILED}" -gt 0 ]]; then
  exit 1
fi

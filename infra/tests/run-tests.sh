#!/usr/bin/env bash
# Infra test runner (unit + optional smoke when host.env is configured).
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

echo "==> unit: checks"
"${ROOT}/tests/unit/checks.test.sh"

echo "==> unit: compose"
"${ROOT}/tests/unit/compose.test.sh"

echo "==> unit: minio bucket"
chmod +x "${ROOT}/tests/unit/minio-bucket.test.sh"
"${ROOT}/tests/unit/minio-bucket.test.sh"

echo "==> unit: nginx VPS (prod default)"
chmod +x "${ROOT}/tests/unit/nginx-vps.test.sh"
"${ROOT}/tests/unit/nginx-vps.test.sh"

echo "==> unit: caddy reverse proxy (dev overlay)"
chmod +x "${ROOT}/tests/unit/caddy-reverse-proxy.test.sh" \
  "${ROOT}/scripts/render-caddyfile.sh" "${ROOT}/scripts/caddy-entrypoint.sh"
"${ROOT}/tests/unit/caddy-reverse-proxy.test.sh"

echo "==> unit: deploy"
chmod +x "${ROOT}/tests/unit/deploy.test.sh" "${ROOT}/scripts/deploy.sh"
"${ROOT}/tests/unit/deploy.test.sh"

echo "==> e2e: docker provision (optional)"
if [[ -x "${ROOT}/tests/e2e/docker-provision.sh" ]]; then
  "${ROOT}/tests/e2e/docker-provision.sh"
fi

echo "==> e2e: docker compose stack (optional)"
if [[ -x "${ROOT}/tests/e2e/docker-compose-stack.sh" ]]; then
  chmod +x "${ROOT}/tests/e2e/docker-compose-stack.sh"
  "${ROOT}/tests/e2e/docker-compose-stack.sh"
fi

echo "==> e2e: minio private bucket (optional)"
if [[ -x "${ROOT}/tests/e2e/minio-bucket-private.sh" ]]; then
  chmod +x "${ROOT}/tests/e2e/minio-bucket-private.sh"
  "${ROOT}/tests/e2e/minio-bucket-private.sh"
fi

echo "==> e2e: HTTPS reverse proxy (optional)"
if [[ -x "${ROOT}/tests/e2e/https-reverse-proxy.sh" ]]; then
  chmod +x "${ROOT}/tests/e2e/https-reverse-proxy.sh"
  "${ROOT}/tests/e2e/https-reverse-proxy.sh"
fi

echo "==> shellcheck"
if command -v shellcheck >/dev/null 2>&1; then
  find "${ROOT}/scripts" "${ROOT}/tests" -type f -name '*.sh' -print0 |
    xargs -0 shellcheck -S warning -x
else
  echo "WARN: shellcheck not installed — skip (install with: brew install shellcheck)"
fi

if [[ -f "${ROOT}/host.env" ]]; then
  echo "==> smoke: remote VPS (host.env present)"
  # shellcheck disable=SC1091
  source "${ROOT}/host.env"
  "${ROOT}/scripts/smoke-vps-provision.sh"
  echo "==> smoke: remote VPS deploy (host.env present)"
  chmod +x "${ROOT}/scripts/smoke-vps-deploy.sh"
  "${ROOT}/scripts/smoke-vps-deploy.sh"
else
  echo "==> smoke: skipped (no infra/host.env — configure after VPS provision)"
fi

echo "All infra tests passed."

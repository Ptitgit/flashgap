#!/usr/bin/env bash
# Infra test runner (unit + optional smoke when host.env is configured).
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

echo "==> unit: checks"
"${ROOT}/tests/unit/checks.test.sh"

echo "==> e2e: docker provision (optional)"
if [[ -x "${ROOT}/tests/e2e/docker-provision.sh" ]]; then
  "${ROOT}/tests/e2e/docker-provision.sh"
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
else
  echo "==> smoke: skipped (no infra/host.env — configure after VPS provision)"
fi

echo "All infra tests passed."

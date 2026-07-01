#!/usr/bin/env bash
# Run a command in Ubuntu 24.04 when host lacks Linux tools (e.g. flock on macOS).
set -euo pipefail

if [[ "${1:-}" == "" ]]; then
  echo "Usage: webhook-linux-runner.sh <bash-script-as-argument>" >&2
  exit 1
fi

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

if ! command -v docker >/dev/null 2>&1; then
  echo "ERROR: docker required for Linux webhook tests on this host" >&2
  exit 1
fi

docker run --rm \
  -v "${ROOT}:/flashgap:ro" \
  -w /flashgap \
  ubuntu:24.04 \
  bash -lc "
set -euo pipefail
export DEBIAN_FRONTEND=noninteractive
apt-get update -qq >/dev/null
apt-get install -qq -y python3 curl openssl util-linux ca-certificates >/dev/null
$1
"

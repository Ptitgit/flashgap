#!/usr/bin/env bash
# E2E: run provision-vps.sh inside Ubuntu 24.04 (no SSH — fast, CI-friendly).
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
IMAGE="flashgap-vps-e2e:ubuntu24"
CONTAINER="flashgap-vps-e2e-$$"
KEY_DIR="$(mktemp -d)"
trap 'docker rm -f "${CONTAINER}" 2>/dev/null || true; rm -rf "${KEY_DIR}"' EXIT

if ! command -v docker >/dev/null 2>&1; then
  echo "SKIP: docker not available"
  exit 0
fi

ssh-keygen -t ed25519 -f "${KEY_DIR}/id_ed25519" -N "" -q

if ! docker image inspect "${IMAGE}" >/dev/null 2>&1; then
  docker build -t "${IMAGE}" -f - "${ROOT}" <<'DOCKERFILE'
FROM ubuntu:24.04
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update -qq \
  && apt-get install -y -qq openssh-server sudo ufw ca-certificates curl gnupg unattended-upgrades \
  && mkdir -p /var/run/sshd \
  && ssh-keygen -A
EXPOSE 22
CMD ["sleep", "infinity"]
DOCKERFILE
fi

docker run -d --name "${CONTAINER}" --cap-add=NET_ADMIN "${IMAGE}" sleep infinity

FLASHGAP_DEPLOY_SSH_PUBKEY="$(cat "${KEY_DIR}/id_ed25519.pub")"
export FLASHGAP_DEPLOY_SSH_PUBKEY
FLASHGAP_SSH_RESTRICT_IP="127.0.0.1"
export FLASHGAP_SSH_RESTRICT_IP

docker exec -i \
  -e FLASHGAP_DEPLOY_SSH_PUBKEY \
  -e FLASHGAP_SSH_RESTRICT_IP \
  -e FLASHGAP_PROVISION_SKIP_UPGRADE=1 \
  -e FLASHGAP_PROVISION_E2E=1 \
  "${CONTAINER}" bash -s <"${ROOT}/scripts/provision-vps.sh"

# shellcheck source=../../scripts/lib/checks.sh
source "${ROOT}/scripts/lib/checks.sh"

docker exec "${CONTAINER}" getent passwd deploy >/dev/null
docker exec "${CONTAINER}" test -f /home/deploy/.ssh/authorized_keys

OS_RELEASE="$(docker exec "${CONTAINER}" cat /etc/os-release)"
is_ubuntu_lts "${OS_RELEASE}" || {
  echo "E2E: expected Ubuntu LTS" >&2
  exit 1
}

SSHD_CONFIG="$(docker exec "${CONTAINER}" cat /etc/ssh/sshd_config.d/99-flashgap.conf)"
[[ "$(sshd_password_auth_disabled "${SSHD_CONFIG}")" == "yes" ]]

docker exec "${CONTAINER}" test -f /etc/sudoers.d/deploy

# UFW : inactif dans Docker sans systemd — tests unitaires + smoke VPS réel

DF_OUTPUT="$(docker exec "${CONTAINER}" df -h /)"
DISK_GB="$(parse_disk_gb_from_df "${DF_OUTPUT}")"
if [[ "${DISK_GB}" -lt "$(min_disk_gb)" ]]; then
  echo "WARN: docker root fs < $(min_disk_gb) GB in e2e (${DISK_GB} GB) — OK on real VPS"
fi

echo "E2E docker provision: ok"

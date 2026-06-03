#!/usr/bin/env bash
# Bootstrap a fresh Ubuntu VPS for Flashgap V0.
# Run as root on the server (or: ssh root@host 'bash -s' < provision-vps.sh).
#
# Required env:
#   FLASHGAP_DEPLOY_SSH_PUBKEY — public key for user deploy
# Optional:
#   FLASHGAP_SSH_RESTRICT_IP        — source IP allowed on port 22 (recommended)
#   FLASHGAP_DEPLOY_USER            — default: deploy
#   FLASHGAP_PROVISION_SKIP_UPGRADE — set to 1 for fast e2e Docker tests only (prod: leave unset)
#   FLASHGAP_PROVISION_E2E          — set to 1 in docker e2e only (skips UFW; use smoke on real VPS)
set -euo pipefail

DEPLOY_USER="${FLASHGAP_DEPLOY_USER:-deploy}"
SSH_RESTRICT_IP="${FLASHGAP_SSH_RESTRICT_IP:-}"

if [[ "$(id -u)" -ne 0 ]]; then
  echo "Run as root on the VPS." >&2
  exit 1
fi

if [[ -z "${FLASHGAP_DEPLOY_SSH_PUBKEY:-}" ]]; then
  echo "Set FLASHGAP_DEPLOY_SSH_PUBKEY to the deploy user's public key." >&2
  exit 1
fi

export DEBIAN_FRONTEND=noninteractive

echo "==> apt update"
apt-get update -qq

if [[ "${FLASHGAP_PROVISION_SKIP_UPGRADE:-}" == "1" ]]; then
  echo "==> apt upgrade skipped (FLASHGAP_PROVISION_SKIP_UPGRADE)"
else
  echo "==> apt upgrade"
  apt-get upgrade -y -qq
fi

echo "==> base packages"
apt-get install -y -qq ca-certificates curl gnupg ufw unattended-upgrades

echo "==> deploy user: ${DEPLOY_USER}"
if ! id "${DEPLOY_USER}" &>/dev/null; then
  useradd -m -s /bin/bash "${DEPLOY_USER}"
fi

install -d -m 700 -o "${DEPLOY_USER}" -g "${DEPLOY_USER}" "/home/${DEPLOY_USER}/.ssh"
echo "${FLASHGAP_DEPLOY_SSH_PUBKEY}" >"/home/${DEPLOY_USER}/.ssh/authorized_keys"
chown "${DEPLOY_USER}:${DEPLOY_USER}" "/home/${DEPLOY_USER}/.ssh/authorized_keys"
chmod 600 "/home/${DEPLOY_USER}/.ssh/authorized_keys"

echo "==> limited sudo for ${DEPLOY_USER}"
cat >/etc/sudoers.d/"${DEPLOY_USER}" <<EOF
# Flashgap deploy — limited sudo (docker + ufw status only)
${DEPLOY_USER} ALL=(ALL) NOPASSWD: /usr/bin/docker, /usr/bin/docker compose, /usr/bin/docker-compose, /usr/sbin/ufw
EOF
chmod 440 /etc/sudoers.d/"${DEPLOY_USER}"

echo "==> SSH hardening"
mkdir -p /etc/ssh/sshd_config.d
cat >/etc/ssh/sshd_config.d/99-flashgap.conf <<'EOF'
PasswordAuthentication no
KbdInteractiveAuthentication no
PermitRootLogin prohibit-password
EOF
if command -v systemctl >/dev/null 2>&1 && systemctl is-system-running --quiet 2>/dev/null; then
  systemctl reload ssh 2>/dev/null || systemctl reload sshd 2>/dev/null || true
fi

if [[ "${FLASHGAP_PROVISION_E2E:-}" == "1" ]]; then
  echo "==> UFW skipped (e2e Docker — valider avec smoke-vps-provision.sh sur le VPS réel)"
else
  echo "==> UFW"
  ufw --force reset
  ufw default deny incoming
  ufw default allow outgoing
  ufw allow 80/tcp
  ufw allow 443/tcp
  if [[ -n "${SSH_RESTRICT_IP}" ]]; then
    ufw allow from "${SSH_RESTRICT_IP}" to any port 22 proto tcp
  else
    echo "WARNING: FLASHGAP_SSH_RESTRICT_IP not set — SSH open to Anywhere (not recommended for prod)" >&2
    ufw allow 22/tcp
  fi
  ufw --force enable
fi

echo "==> hostname hint (set FLASHGAP_PUBLIC_HOSTNAME in host.env)"
echo "Provision complete. Log in: ssh ${DEPLOY_USER}@<public-ip>"

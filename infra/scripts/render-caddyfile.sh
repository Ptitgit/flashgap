#!/bin/sh
# Render Caddyfile from PUBLIC_HOSTNAME / ACME_EMAIL (stdout).
# localhost → tls internal (dev/e2e) ; real domain → automatic Let's Encrypt.
set -eu

HOST="${PUBLIC_HOSTNAME:-localhost}"
EMAIL="${ACME_EMAIL:-}"

if [ "${HOST}" = "localhost" ] || [ "${HOST}" = "127.0.0.1" ]; then
  cat <<'EOF'
localhost, 127.0.0.1 {
	tls internal
	reverse_proxy api:3000
}
EOF
  exit 0
fi

if [ -n "${EMAIL}" ]; then
  cat <<EOF
{
	email ${EMAIL}
}

${HOST} {
	reverse_proxy api:3000
}
EOF
else
  cat <<EOF
${HOST} {
	reverse_proxy api:3000
}
EOF
fi

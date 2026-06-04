#!/bin/sh
set -eu
/render-caddyfile.sh >/etc/caddy/Caddyfile
exec caddy run --config /etc/caddy/Caddyfile --adapter caddyfile

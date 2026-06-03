#!/usr/bin/env sh
# Create the Flashgap photos bucket and deny anonymous (public) access.
set -eu

MINIO_ENDPOINT="${MINIO_ENDPOINT:-http://minio:9000}"
MAX_ATTEMPTS="${MINIO_INIT_MAX_ATTEMPTS:-30}"
SLEEP_SECONDS="${MINIO_INIT_SLEEP_SECONDS:-2}"

require_var() {
  var_name="$1"
  eval "value=\${$var_name:-}"
  if [ -z "${value}" ]; then
    echo "minio-init: missing required env ${var_name}" >&2
    exit 1
  fi
}

require_var MINIO_ROOT_USER
require_var MINIO_ROOT_PASSWORD
require_var MINIO_BUCKET

attempt=1
while [ "${attempt}" -le "${MAX_ATTEMPTS}" ]; do
  if mc alias set local "${MINIO_ENDPOINT}" "${MINIO_ROOT_USER}" "${MINIO_ROOT_PASSWORD}" >/dev/null 2>&1; then
    break
  fi
  echo "minio-init: waiting for MinIO (${attempt}/${MAX_ATTEMPTS})..."
  attempt=$((attempt + 1))
  sleep "${SLEEP_SECONDS}"
done

if [ "${attempt}" -gt "${MAX_ATTEMPTS}" ]; then
  echo "minio-init: MinIO not reachable at ${MINIO_ENDPOINT}" >&2
  exit 1
fi

mc mb --ignore-existing "local/${MINIO_BUCKET}"
mc anonymous set none "local/${MINIO_BUCKET}"

echo "minio-init: bucket '${MINIO_BUCKET}' ready (private)"

#!/usr/bin/env bash
# E2E: stack up — verify MinIO bucket exists and anonymous access is denied
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
COMPOSE_FILE="${ROOT}/docker-compose.yml"
ENV_FILE="${ROOT}/.env.example"
PROJECT="flashgap-minio-e2e-$$"

if ! command -v docker >/dev/null 2>&1; then
  echo "SKIP: docker not installed"
  exit 0
fi

# shellcheck disable=SC1090
source "${ENV_FILE}"

cleanup() {
  docker compose -f "${COMPOSE_FILE}" --env-file "${ENV_FILE}" \
    -p "${PROJECT}" down -v --remove-orphans >/dev/null 2>&1 || true
}
trap cleanup EXIT

echo "==> compose up minio + init (${PROJECT})"
docker compose -f "${COMPOSE_FILE}" --env-file "${ENV_FILE}" \
  -p "${PROJECT}" up -d minio

for _ in $(seq 1 30); do
  if docker compose -f "${COMPOSE_FILE}" --env-file "${ENV_FILE}" \
    -p "${PROJECT}" ps minio 2>/dev/null | grep -q '(healthy)'; then
    break
  fi
  sleep 2
done

docker compose -f "${COMPOSE_FILE}" --env-file "${ENV_FILE}" \
  -p "${PROJECT}" up --abort-on-container-exit --exit-code-from minio-init minio-init

echo "==> minio-init completed"

echo "==> verify bucket exists and is private"
NETWORK="$(
  docker compose -f "${COMPOSE_FILE}" --env-file "${ENV_FILE}" \
    -p "${PROJECT}" ps -q minio | xargs docker inspect -f '{{range $k, $v := .NetworkSettings.Networks}}{{$k}}{{end}}'
)"

VERIFY_OUTPUT="$(
  docker run --rm --network "${NETWORK}" \
    --entrypoint /bin/sh \
    minio/mc@sha256:a7fe349ef4bd8521fb8497f55c6042871b2ae640607cf99d9bede5e9bdf11727 \
    -c "
      set -e
      mc alias set local http://minio:9000 '${MINIO_ROOT_USER}' '${MINIO_ROOT_PASSWORD}'
      mc ls 'local/${MINIO_BUCKET}' >/dev/null
      mc anonymous get 'local/${MINIO_BUCKET}'
    "
)"

if ! echo "${VERIFY_OUTPUT}" | grep -qiE "none|private|no policy"; then
  echo "FAIL: expected private bucket policy, got:"
  echo "${VERIFY_OUTPUT}"
  exit 1
fi

echo "==> verify anonymous HTTP GET is denied"
MINIO_IP="$(
  docker compose -f "${COMPOSE_FILE}" --env-file "${ENV_FILE}" \
    -p "${PROJECT}" ps -q minio | xargs docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}'
)"

HTTP_CODE="$(
  docker run --rm --network "${NETWORK}" curlimages/curl:8.13.0 \
    -s -o /dev/null -w '%{http_code}' \
    "http://${MINIO_IP}:9000/${MINIO_BUCKET}/"
)"

if [[ "${HTTP_CODE}" == "200" ]]; then
  echo "FAIL: anonymous GET on bucket returned 200 (public access)"
  exit 1
fi

echo "E2E minio private bucket: ok"

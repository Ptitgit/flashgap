#!/usr/bin/env bash
# GitHub webhook helpers: HMAC signature verification and push-to-main detection.

github_webhook_compute_signature() {
  local secret="$1"
  local body="$2"
  local digest
  digest="$(printf '%s' "${body}" | openssl dgst -sha256 -hmac "${secret}" | awk '{print $2}')"
  printf 'sha256=%s' "${digest}"
}

github_webhook_verify_signature() {
  local secret="$1"
  local signature_header="$2"
  local body="$3"

  if [[ -z "${secret}" || -z "${signature_header}" ]]; then
    return 1
  fi

  local expected
  expected="$(github_webhook_compute_signature "${secret}" "${body}")"
  [[ "${signature_header}" == "${expected}" ]]
}

github_webhook_extract_ref() {
  local body="$1"
  if [[ "${body}" =~ \"ref\":[[:space:]]*\"([^\"]+)\" ]]; then
    printf '%s' "${BASH_REMATCH[1]}"
  fi
}

github_webhook_is_main_push() {
  local event="$1"
  local ref="$2"
  [[ "${event}" == "push" && "${ref}" == "refs/heads/main" ]]
}

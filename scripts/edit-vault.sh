#!/usr/bin/env sh
set -eu

VAULT_FILE="${VAULT_FILE:-inventory/gpu-cluster/group_vars/gpu_cluster/vault.yml}"
VAULT_EXAMPLE="${VAULT_EXAMPLE:-inventory/gpu-cluster/group_vars/gpu_cluster/vault.yml.example}"
VAULT_PASSWORD_FILE="${VAULT_PASSWORD_FILE:-.vault_pass}"

if test ! -f "${VAULT_PASSWORD_FILE}"; then
  echo "missing ${VAULT_PASSWORD_FILE}" >&2
  echo "create it locally with: printf '%s\n' 'your-vault-password' > ${VAULT_PASSWORD_FILE}" >&2
  exit 2
fi

if test -f "${VAULT_FILE}"; then
  exec uv run ansible-vault edit "${VAULT_FILE}" --vault-password-file "${VAULT_PASSWORD_FILE}"
fi

tmp="$(mktemp)"
trap 'rm -f "${tmp}"' EXIT
cp "${VAULT_EXAMPLE}" "${tmp}"
uv run ansible-vault encrypt "${tmp}" --output "${VAULT_FILE}" --vault-password-file "${VAULT_PASSWORD_FILE}"
exec uv run ansible-vault edit "${VAULT_FILE}" --vault-password-file "${VAULT_PASSWORD_FILE}"

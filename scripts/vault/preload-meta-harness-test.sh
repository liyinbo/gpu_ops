#!/usr/bin/env sh
set -eu

repo_dir=$(CDPATH= cd -- "$(dirname -- "$0")/../.." && pwd)
kubeconfig=${KUBECONFIG:-"${repo_dir}/kubeconfig-gpu-cluster.yaml"}
token_cache=/home/vault/.vault-token

cleanup() {
  kubectl --kubeconfig "$kubeconfig" -n vault exec vault-0 -- \
    rm -f "$token_cache" >/dev/null 2>&1 || true
}
trap cleanup EXIT HUP INT TERM

KUBECONFIG="$kubeconfig" "${repo_dir}/scripts/vault/check-health.sh"

old_tty=$(stty -g </dev/tty)
trap 'stty "$old_tty" </dev/tty; cleanup' EXIT HUP INT TERM
stty -echo </dev/tty
printf 'Vault initial root token: ' >/dev/tty
IFS= read -r root_token </dev/tty
stty "$old_tty" </dev/tty
printf '\n' >/dev/tty

printf '%s\n' "$root_token" | kubectl --kubeconfig "$kubeconfig" -n vault exec -i vault-0 -- \
  vault login -no-print token=-
unset root_token

synthetic_secret=$(openssl rand -hex 32)
expires_at=$(date -u -v+30M '+%Y-%m-%dT%H:%M:%SZ')
printf '%s' "$synthetic_secret" | jq -Rs --arg expires_at "$expires_at" \
  '{data: {username: "vault-dev-test", secret: ., host: "forgejo.invalid", repository: "limbo/non-production.git", scope: "read", expiresAt: $expires_at, revoked: false}}' \
  | kubectl --kubeconfig "$kubeconfig" -n vault exec -i vault-0 -- \
      vault write meta-harness-dev/data/tests/credential-resolve -
unset synthetic_secret

echo "Synthetic non-production credential record loaded; expires at ${expires_at}"

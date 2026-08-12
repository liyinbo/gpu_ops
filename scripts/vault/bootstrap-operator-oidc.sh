#!/usr/bin/env sh
set -eu

repo_dir=$(CDPATH= cd -- "$(dirname -- "$0")/../.." && pwd)
kubeconfig=${KUBECONFIG:-"${repo_dir}/kubeconfig-gpu-cluster.yaml"}
storage_repo_dir=$(CDPATH= cd -- "${repo_dir}/../storage_server_ops" && pwd)
authentik_kubeconfig=${AUTHENTIK_KUBECONFIG:-"${storage_repo_dir}/kubeconfig.yaml"}
operator_policy_file="${repo_dir}/apps/vault/policies/meta-harness-operator.hcl"
token_cache=/home/vault/.vault-token

cleanup() {
  kubectl --kubeconfig "$kubeconfig" -n vault exec vault-0 -- \
    rm -f "$token_cache" >/dev/null 2>&1 || true
}

restore_tty_and_cleanup() {
  stty "$old_tty" </dev/tty 2>/dev/null || true
  cleanup
}

trap cleanup EXIT HUP INT TERM

KUBECONFIG="$kubeconfig" "${repo_dir}/scripts/vault/check-health.sh"

if ! test -r /dev/tty; then
  echo "A TTY is required for the hidden initial root-token prompt" >&2
  exit 1
fi

old_tty=$(stty -g </dev/tty)
trap restore_tty_and_cleanup EXIT HUP INT TERM
stty -echo </dev/tty
printf 'Vault initial root token: ' >/dev/tty
IFS= read -r root_token </dev/tty
stty "$old_tty" </dev/tty
printf '\n' >/dev/tty

printf '%s\n' "$root_token" | kubectl --kubeconfig "$kubeconfig" -n vault exec -i vault-0 -- \
  vault login -no-print token=-
unset root_token

if kubectl --kubeconfig "$kubeconfig" -n vault exec vault-0 -- \
  vault auth list -format=json | jq -e 'has("oidc/")' >/dev/null; then
  kubectl --kubeconfig "$kubeconfig" -n vault exec vault-0 -- \
    vault auth list -format=json | jq -e '.["oidc/"].type == "oidc"' >/dev/null
else
  kubectl --kubeconfig "$kubeconfig" -n vault exec vault-0 -- \
    vault auth enable -path=oidc oidc
fi

kubectl --kubeconfig "$kubeconfig" -n vault exec -i vault-0 -- \
  vault policy write meta-harness-operator - <"$operator_policy_file"

kubectl --kubeconfig "$authentik_kubeconfig" -n authentik \
  get secret authentik-vault-operator-blueprint -o json | \
  jq -r '.data["client-secret"]' | base64 -d | \
  jq -Rs '{
    oidc_discovery_url: "https://auth.home.hope-leniency.com/application/o/gpu-vault-operator/",
    oidc_client_id: "gpu-vault-operator",
    oidc_client_secret: .,
    default_role: "meta-harness-operator"
  }' | \
  kubectl --kubeconfig "$kubeconfig" -n vault exec -i vault-0 -- \
    vault write auth/oidc/config -

kubectl --kubeconfig "$kubeconfig" -n vault exec vault-0 -- \
  vault write auth/oidc/role/meta-harness-operator \
    role_type=oidc \
    user_claim=sub \
    groups_claim=groups \
    'bound_claims={"groups":["Vault GPU Operators"]}' \
    allowed_redirect_uris=http://localhost:8250/oidc/callback \
    oidc_scopes=profile,email \
    token_policies=meta-harness-operator \
    token_no_default_policy=true \
    token_ttl=30m \
    token_max_ttl=1h \
    verbose_oidc_logging=false

kubectl --kubeconfig "$kubeconfig" -n vault exec vault-0 -- \
  vault read -format=json auth/oidc/role/meta-harness-operator | \
  jq -e '.data.role_type == "oidc" and
    .data.user_claim == "sub" and
    .data.groups_claim == "groups" and
    .data.bound_claims.groups == ["Vault GPU Operators"] and
    .data.allowed_redirect_uris == ["http://localhost:8250/oidc/callback"] and
    .data.token_policies == ["meta-harness-operator"] and
    .data.token_no_default_policy == true' >/dev/null

echo "Restricted Meta Harness operator OIDC role is configured"

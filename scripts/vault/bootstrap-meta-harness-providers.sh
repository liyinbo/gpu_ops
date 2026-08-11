#!/usr/bin/env sh
set -eu

repo_dir=$(CDPATH= cd -- "$(dirname -- "$0")/../.." && pwd)
kubeconfig=${KUBECONFIG:-"${repo_dir}/kubeconfig-gpu-cluster.yaml"}
ingest_policy_file="${repo_dir}/apps/vault/policies/meta-harness-credential-ingest.hcl"
worker_policy_file="${repo_dir}/apps/vault/policies/meta-harness-worker.hcl"
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

kubectl --kubeconfig "$kubeconfig" -n vault exec vault-0 -- \
  vault secrets list -format=json | \
  jq -e '.["meta-harness-dev/"].type == "kv" and .["meta-harness-dev/"].options.version == "2"' >/dev/null
kubectl --kubeconfig "$kubeconfig" -n vault exec vault-0 -- \
  vault auth list -format=json | jq -e '.["kubernetes/"].type == "kubernetes"' >/dev/null

kubectl --kubeconfig "$kubeconfig" -n vault exec -i vault-0 -- \
  vault policy write meta-harness-credential-ingest - <"$ingest_policy_file"
kubectl --kubeconfig "$kubeconfig" -n vault exec -i vault-0 -- \
  vault policy write meta-harness-worker - <"$worker_policy_file"

kubectl --kubeconfig "$kubeconfig" -n vault exec vault-0 -- \
  vault write auth/kubernetes/role/meta-harness-credential-ingest \
    bound_service_account_names=meta-harness-credential-ingest \
    bound_service_account_namespaces=meta-harness \
    audience=vault \
    policies=meta-harness-credential-ingest \
    token_ttl=20m \
    token_max_ttl=1h

kubectl --kubeconfig "$kubeconfig" -n vault exec vault-0 -- \
  vault write auth/kubernetes/role/meta-harness-worker \
    bound_service_account_names=meta-harness-worker \
    bound_service_account_namespaces=meta-harness \
    audience=vault \
    policies=meta-harness-worker \
    token_ttl=20m \
    token_max_ttl=1h

kubectl --kubeconfig "$kubeconfig" -n vault exec vault-0 -- \
  vault read -format=json auth/kubernetes/role/meta-harness-credential-ingest | \
  jq -e '.data.bound_service_account_names == ["meta-harness-credential-ingest"] and
    .data.bound_service_account_namespaces == ["meta-harness"] and
    .data.audience == "vault" and .data.token_policies == ["meta-harness-credential-ingest"]' >/dev/null
kubectl --kubeconfig "$kubeconfig" -n vault exec vault-0 -- \
  vault read -format=json auth/kubernetes/role/meta-harness-worker | \
  jq -e '.data.bound_service_account_names == ["meta-harness-worker"] and
    .data.bound_service_account_namespaces == ["meta-harness"] and
    .data.audience == "vault" and .data.token_policies == ["meta-harness-worker"]' >/dev/null

echo "Provider ingest and worker policies and Kubernetes auth roles are configured"

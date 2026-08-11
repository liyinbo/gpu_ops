#!/usr/bin/env sh
set -eu

repo_dir=$(CDPATH= cd -- "$(dirname -- "$0")/../.." && pwd)
kubeconfig=${KUBECONFIG:-"${repo_dir}/kubeconfig-gpu-cluster.yaml"}
ingest_policy_file="${repo_dir}/apps/vault/policies/meta-harness-credential-ingest.hcl"
worker_policy_file="${repo_dir}/apps/vault/policies/meta-harness-worker.hcl"
token_cache=/home/vault/.vault-token
port_forward_pid=

cleanup() {
  if test -n "$port_forward_pid"; then
    kill "$port_forward_pid" >/dev/null 2>&1 || true
    wait "$port_forward_pid" >/dev/null 2>&1 || true
  fi
  kubectl --kubeconfig "$kubeconfig" -n vault exec vault-0 -- \
    rm -f "$token_cache" >/dev/null 2>&1 || true
}
trap cleanup EXIT HUP INT TERM

KUBECONFIG="$kubeconfig" "${repo_dir}/scripts/vault/check-health.sh"

if ! test -t 0 || ! test -t 1; then
  echo "An interactive TTY is required for browser-backed Vault OIDC login" >&2
  exit 1
fi

kubectl --kubeconfig "$kubeconfig" -n vault port-forward pod/vault-0 \
  8250:8250 >/dev/null 2>&1 &
port_forward_pid=$!

echo "Open the Authentik URL printed below and sign in as a Vault GPU Operators member."
kubectl --kubeconfig "$kubeconfig" -n vault exec -it vault-0 -- \
  vault login -no-print -method=oidc -path=oidc \
    role=meta-harness-operator \
    port=8250 \
    callbackhost=localhost \
    listenaddress=0.0.0.0 \
    skip_browser=true

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

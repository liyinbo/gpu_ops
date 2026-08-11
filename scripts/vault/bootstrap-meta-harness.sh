#!/usr/bin/env sh
set -eu

repo_dir=$(CDPATH= cd -- "$(dirname -- "$0")/../.." && pwd)
kubeconfig=${KUBECONFIG:-"${repo_dir}/kubeconfig-gpu-cluster.yaml"}
policy_file="${repo_dir}/apps/vault/policies/meta-harness-workspace-broker-dev.hcl"
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

if ! kubectl --kubeconfig "$kubeconfig" -n vault exec vault-0 -- \
  vault audit list -format=json | jq -e '.["file/"].options.file_path == "/vault/audit/audit.log"' >/dev/null; then
  kubectl --kubeconfig "$kubeconfig" -n vault exec vault-0 -- \
    vault audit enable file file_path=/vault/audit/audit.log
fi

if ! kubectl --kubeconfig "$kubeconfig" -n vault exec vault-0 -- \
  vault secrets list -format=json | jq -e '.["meta-harness-dev/"].type == "kv" and .["meta-harness-dev/"].options.version == "2"' >/dev/null; then
  if kubectl --kubeconfig "$kubeconfig" -n vault exec vault-0 -- \
    vault secrets list -format=json | jq -e 'has("meta-harness-dev/")' >/dev/null; then
    echo "meta-harness-dev/ exists but is not KV v2" >&2
    exit 1
  fi
  kubectl --kubeconfig "$kubeconfig" -n vault exec vault-0 -- \
    vault secrets enable -path=meta-harness-dev -version=2 kv
fi

kubectl --kubeconfig "$kubeconfig" -n vault exec -i vault-0 -- \
  vault policy write meta-harness-workspace-broker-dev - <"$policy_file"

if ! kubectl --kubeconfig "$kubeconfig" -n vault exec vault-0 -- \
  vault auth list -format=json | jq -e '.["kubernetes/"].type == "kubernetes"' >/dev/null; then
  if kubectl --kubeconfig "$kubeconfig" -n vault exec vault-0 -- \
    vault auth list -format=json | jq -e 'has("kubernetes/")' >/dev/null; then
    echo "kubernetes/ exists but is not Kubernetes auth" >&2
    exit 1
  fi
  kubectl --kubeconfig "$kubeconfig" -n vault exec vault-0 -- \
    vault auth enable kubernetes
fi

kubectl --kubeconfig "$kubeconfig" -n vault exec vault-0 -- \
  vault write auth/kubernetes/config \
    kubernetes_host=https://kubernetes.default.svc:443 \
    kubernetes_ca_cert=@/var/run/secrets/kubernetes.io/serviceaccount/ca.crt

kubectl --kubeconfig "$kubeconfig" -n vault exec vault-0 -- \
  vault write auth/kubernetes/role/meta-harness-workspace-broker-dev \
    bound_service_account_names=meta-harness-workspace-broker \
    bound_service_account_namespaces=meta-harness \
    audience=vault \
    policies=meta-harness-workspace-broker-dev \
    token_ttl=20m \
    token_max_ttl=1h

kubectl --kubeconfig "$kubeconfig" -n vault exec vault-0 -- \
  vault audit list -format=json | jq -e '.["file/"].options.file_path == "/vault/audit/audit.log"' >/dev/null
kubectl --kubeconfig "$kubeconfig" -n vault exec vault-0 -- \
  vault secrets list -format=json | jq -e '.["meta-harness-dev/"].options.version == "2"' >/dev/null
kubectl --kubeconfig "$kubeconfig" -n vault exec vault-0 -- \
  vault auth list -format=json | jq -e '.["kubernetes/"].type == "kubernetes"' >/dev/null

echo "Vault audit, KV v2, exact-path policy, Kubernetes auth, and broker role are configured"

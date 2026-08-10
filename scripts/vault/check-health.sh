#!/usr/bin/env sh
set -eu

repo_dir=$(CDPATH= cd -- "$(dirname -- "$0")/../.." && pwd)
kubeconfig=${KUBECONFIG:-"${repo_dir}/kubeconfig-gpu-cluster.yaml"}
expected=${1:-healthy}

case "$expected" in
  healthy|--expect-uninitialized) ;;
  *) echo "usage: $0 [--expect-uninitialized]" >&2; exit 64 ;;
esac

status_json=$(kubectl --kubeconfig "$kubeconfig" -n vault exec vault-0 -- \
  vault status -format=json 2>/dev/null) || status_rc=$?
status_rc=${status_rc:-0}
if [ "$status_rc" -ne 0 ] && [ "$status_rc" -ne 2 ]; then
  echo "TLS-validated Vault status check failed" >&2
  exit 1
fi

initialized=$(printf '%s' "$status_json" | jq -r '.initialized')
sealed=$(printf '%s' "$status_json" | jq -r '.sealed')
printf 'vault-0 initialized=%s sealed=%s\n' "$initialized" "$sealed"

if [ "$expected" = "--expect-uninitialized" ]; then
  [ "$initialized" = false ] && [ "$sealed" = true ]
  echo "Vault uninitialized gate check passed"
else
  [ "$initialized" = true ] && [ "$sealed" = false ]
  echo "Vault health check passed"
fi

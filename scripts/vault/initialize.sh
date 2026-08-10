#!/usr/bin/env sh
set -eu

repo_dir=$(CDPATH= cd -- "$(dirname -- "$0")/../.." && pwd)
kubeconfig=${KUBECONFIG:-"${repo_dir}/kubeconfig-gpu-cluster.yaml"}

if [ "$#" -ne 1 ]; then
  echo "usage: $0 /absolute/path/outside-repository/vault-init.json" >&2
  exit 64
fi

output_path=$1
case "$output_path" in
  /*) ;;
  *) echo "output path must be absolute" >&2; exit 64 ;;
esac
case "$output_path" in
  "$repo_dir"/*) echo "refusing to store initialization material in the repository" >&2; exit 1 ;;
esac
[ ! -e "$output_path" ] || { echo "refusing to replace $output_path" >&2; exit 1; }

output_dir=$(dirname -- "$output_path")
mkdir -p "$output_dir"
chmod 0700 "$output_dir"
umask 077

kubectl --kubeconfig "$kubeconfig" -n vault exec vault-0 -- \
  vault operator init -key-shares=1 -key-threshold=1 -format=json >"${output_path}.partial"
chmod 0600 "${output_path}.partial"
mv "${output_path}.partial" "$output_path"

unseal_key=$(jq -er '.unseal_keys_b64[0]' "$output_path")
printf '%s\n' "$unseal_key" | kubectl --kubeconfig "$kubeconfig" -n vault exec -i vault-0 -- \
  vault operator unseal >/dev/null
unset unseal_key

echo "Vault initialized and unsealed; initialization material written mode 0600 to $output_path"
echo "Move that file into the approved password manager, then remove the local copy."

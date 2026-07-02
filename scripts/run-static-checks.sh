#!/usr/bin/env sh
set -eu

VAULT_PASSWORD_FILE="${VAULT_PASSWORD_FILE:-.vault_pass}"
ANSIBLE_VAULT_ARGS=""

if test -f "${VAULT_PASSWORD_FILE}"; then
  ANSIBLE_VAULT_ARGS="--vault-password-file=${VAULT_PASSWORD_FILE}"
fi

uv run ansible-playbook -i inventory/gpu-cluster/hosts.yml playbooks/00-preflight.yml --syntax-check ${ANSIBLE_VAULT_ARGS}
uv run ansible-playbook -i inventory/gpu-cluster/hosts.yml playbooks/site.yml --syntax-check ${ANSIBLE_VAULT_ARGS}
uv run ansible-playbook -i inventory/gpu-cluster/hosts.yml playbooks/04-flux.yml --syntax-check ${ANSIBLE_VAULT_ARGS}

kubectl kustomize clusters/gpu-cluster >/tmp/gpu-ops-cluster-render.yaml
kubectl kustomize infrastructure/nvidia-gpu-operator >/tmp/gpu-ops-gpu-operator-render.yaml

sh -n scripts/check-gpu-operator.sh
sh -n scripts/check-gpu-runtime-test.sh
sh -n scripts/check-k3s.sh
sh -n scripts/edit-vault.sh

uv run ansible-inventory -i inventory/gpu-cluster/hosts.yml --graph ${ANSIBLE_VAULT_ARGS} >/tmp/gpu-ops-inventory-graph.txt

echo "static checks passed"

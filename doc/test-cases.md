# Test Cases

## Static Checks

### TC-GPU-001 Ansible Site Syntax

Command:

```bash
uv run ansible-playbook -i inventory/gpu-cluster/hosts.yml playbooks/site.yml --syntax-check
```

Expected result: syntax check passes.

When `inventory/gpu-cluster/group_vars/gpu_cluster/vault.yml` exists, run with:

```bash
uv run ansible-playbook -i inventory/gpu-cluster/hosts.yml playbooks/site.yml --syntax-check --vault-password-file=.vault_pass
```

### TC-GPU-002 Flux Playbook Syntax

Command:

```bash
uv run ansible-playbook -i inventory/gpu-cluster/hosts.yml playbooks/04-flux.yml --syntax-check
```

Expected result: syntax check passes.

When the vault file exists, include `--vault-password-file=.vault_pass`.

### TC-GPU-003 Cluster Kustomize Render

Command:

```bash
kubectl kustomize clusters/gpu-cluster
```

Expected result: manifests render without errors.

## Host Provisioning Checks

### TC-GPU-010 Base Playbook

Command:

```bash
uv run ansible-playbook -i inventory/gpu-cluster/hosts.yml playbooks/01-base.yml
```

Expected result: common packages are installed, swap is disabled, required kernel modules are loaded, and sysctls are applied.

### TC-GPU-011 GPU Host Prerequisites Playbook

Command:

```bash
uv run ansible-playbook -i inventory/gpu-cluster/hosts.yml playbooks/02-gpu-runtime.yml
```

Expected result: GPU host prerequisites complete without taking over responsibilities assigned to NVIDIA GPU Operator. `nvidia-smi` output is reported when host drivers are already available.

### TC-GPU-012 k3s Playbook

Command:

```bash
uv run ansible-playbook -i inventory/gpu-cluster/hosts.yml playbooks/03-k3s.yml
```

Expected result: server and agent services are running and kubeconfig is fetched to `kubeconfig-gpu-cluster.yaml`.

## Cluster Checks

### TC-GPU-020 Node Readiness

Command:

```bash
KUBECONFIG_PATH=kubeconfig-gpu-cluster.yaml scripts/check-k3s.sh
```

Expected result: all expected nodes are `Ready`.

### TC-GPU-021 NVIDIA GPU Operator

Command:

```bash
kubectl --kubeconfig kubeconfig-gpu-cluster.yaml get pods -n gpu-operator
kubectl --kubeconfig kubeconfig-gpu-cluster.yaml get clusterpolicy
kubectl --kubeconfig kubeconfig-gpu-cluster.yaml get nodes -o json | jq '.items[].status.allocatable'
```

Expected result: GPU Operator pods are healthy, ClusterPolicy is ready, and GPU nodes expose `nvidia.com/gpu`.

### TC-GPU-022 GPU Runtime Test Pod

Command:

```bash
kubectl --kubeconfig kubeconfig-gpu-cluster.yaml apply -f tests/nvidia-runtime-test.yaml
kubectl --kubeconfig kubeconfig-gpu-cluster.yaml logs pod/nvidia-runtime-test
```

Expected result: pod completes and logs `nvidia-smi` output.

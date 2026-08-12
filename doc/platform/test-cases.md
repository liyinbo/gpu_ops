# Test Cases

## Static Checks

### TC-GPU-000 Local Static Gate

Command:

```bash
scripts/run-static-checks.sh
```

Expected result: Ansible syntax checks, kustomize renders, shell syntax checks, and inventory graph rendering all pass. If `.vault_pass` exists, the script uses it automatically.

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

### TC-GPU-005 Flux Controller Install and Cluster Apply

Command:

```bash
uv run ansible-playbook -i inventory/gpu-cluster/hosts.yml playbooks/04-flux.yml --vault-password-file=.vault_pass
```

Expected result: Flux controllers are installed or confirmed present, and
`clusters/gpu-cluster` is applied to create/update the Forgejo-backed
GitRepository/Kustomization plus the GPU Operator HelmRepository and HelmRelease. The
out-of-band `flux-system/gpu-ops-forgejo` credential must exist first.

### TC-GPU-007 Forgejo Source Migration

Before switching, reconcile a credentialed canary GitRepository against the private Forgejo
URL and compare it with `flux-system/gpu-ops`.

Expected result: both sources are ready at the same full commit and artifact digest. After the
managed switch, `gpu-ops` reports the Forgejo URL and Secret reference; every dependent
Kustomization is ready at the Forgejo revision. StatefulSet UIDs and PVC/PV bindings remain
unchanged, all bound claims remain bound, and no workload resource is pruned or recreated due
to the source-location change. Removing the temporary canary does not affect consumers.

### TC-GPU-003 Cluster Kustomize Render

Command:

```bash
kubectl kustomize clusters/gpu-cluster
```

Expected result: manifests render without errors.

### TC-GPU-004 GPU Operator HelmRelease Render

Command:

```bash
kubectl kustomize infrastructure/nvidia-gpu-operator
```

Expected result: namespace, NVIDIA HelmRepository, and GPU Operator HelmRelease render without errors. The HelmRelease pins the chart version and configures k3s containerd integration.

### TC-GPU-006 Private HTTPS Add-on Render

Command:

```bash
kubectl kustomize infrastructure/traefik
kubectl kustomize infrastructure/cert-manager
kubectl kustomize infrastructure/cert-manager-issuers
```

Expected result: Traefik, cert-manager, and issuer manifests render without errors.

## Host Provisioning Checks

### TC-GPU-009 Preflight Inventory and Host State

Command:

```bash
uv run ansible-playbook -i inventory/gpu-cluster/hosts.yml playbooks/00-preflight.yml --vault-password-file=.vault_pass
```

Expected result: inventory has one k3s server at `192.168.8.130`, no agents, SSH authentication succeeds, OS/kernel/swap facts are reported, Secure Boot state is reported when `mokutil` is available, current `nvidia-smi` state is reported, and current k3s service/kubeconfig state is reported.

For key auth, run with `GPU_OPS_SSH_KEY` pointing at the local private key. For password auth, store `vault_ansible_password` in the ignored encrypted vault file.

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

Expected result: GPU host prerequisites complete without taking over responsibilities assigned to NVIDIA GPU Operator. `/etc/modprobe.d/blacklist-nouveau.conf` prevents `nouveau` from loading and the installed initramfs images are rebuilt when that file changes. The play reports when a reboot is required because `nouveau` is already loaded. `nvidia-smi` output is reported when host drivers are already available.

After the required reboot, verify the module ownership:

```bash
uv run ansible -i inventory/gpu-cluster/hosts.yml gpu_nodes -b \
  -m shell -a 'lsmod | grep -E "nvidia|nouveau"' \
  --vault-password-file=.vault_pass
```

Expected result: NVIDIA modules are listed and `nouveau` is absent.

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

Expected result: all expected nodes are `Ready`; the script exits non-zero if any node does not reach `Ready`.

### TC-GPU-021 NVIDIA GPU Operator

Command:

```bash
KUBECONFIG_PATH=kubeconfig-gpu-cluster.yaml scripts/check-gpu-operator.sh
```

Equivalent manual commands:

```bash
kubectl --kubeconfig kubeconfig-gpu-cluster.yaml get pods -n gpu-operator
kubectl --kubeconfig kubeconfig-gpu-cluster.yaml get clusterpolicy
kubectl --kubeconfig kubeconfig-gpu-cluster.yaml get nodes -o json | jq '.items[].status.allocatable'
```

Expected result: GPU Operator pods are healthy, ClusterPolicy exists, and at least one node exposes positive `nvidia.com/gpu` allocatable resources. The script exits non-zero for unhealthy pods or missing GPU allocatable resources.

### TC-GPU-022 GPU Runtime Test Pod

Command:

```bash
KUBECONFIG_PATH=kubeconfig-gpu-cluster.yaml scripts/check-gpu-runtime-test.sh
```

Expected result: pod completes and logs `nvidia-smi` output containing `NVIDIA-SMI`.

### TC-GPU-040 Private HTTPS Platform Add-ons

Expected result: Traefik exposes an IngressClass named `traefik`, cert-manager CRDs are present, and ClusterIssuer `letsencrypt-prod` exists. Certificate readiness requires the out-of-band `cert-manager/alidns-secrets` DNS credential Secret.

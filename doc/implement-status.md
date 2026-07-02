# Implementation Status

## Current Status

Date: 2026-07-02

The repository at `~/repo/gpu_ops` now provisions the single GPU node at `192.168.8.130`, installs k3s, installs Flux controllers, reconciles NVIDIA GPU Operator through Flux-compatible manifests, and validates GPU scheduling with an NVIDIA runtime test pod. NVIDIA GPU Operator is the selected GPU resource management layer.

## Completed

- Created Git repository.
- Added `AGENTS.md`, `README.md`, `.gitignore`, `pyproject.toml`, `requirements.yml`, and `ansible.cfg`.
- Added sample inventory under `inventory/gpu-cluster`.
- Added roles:
  - `common`
  - `nvidia_container_toolkit`
  - `k3s_server`
  - `k3s_agent`
  - `flux`
- Added playbooks:
  - `playbooks/01-base.yml`
  - `playbooks/02-gpu-runtime.yml`
  - `playbooks/03-k3s.yml`
  - `playbooks/04-flux.yml`
  - `playbooks/site.yml`
- Added GPU runtime test pod manifest.
- Added control documents in `doc/`.
- Removed the standalone NVIDIA device plugin placeholder because GPU Operator is the chosen management path.
- Added Ansible Vault wiring for `ansible_become_password` and `k3s_token`.
- Added encrypted SSH username wiring through `vault_ansible_user`, optional encrypted SSH password wiring through `vault_ansible_password`, and key-based SSH support through the local `GPU_OPS_SSH_KEY` environment variable.
- Configured the single-node inventory target as `gpu-cp01` at `192.168.8.130`.
- Added `playbooks/00-preflight.yml` to validate inventory shape and inspect OS/kernel/swap, Secure Boot, NVIDIA driver visibility, and current k3s state before provisioning.
- Added `doc/ssh-access.md` with key-based and vaulted password SSH access flows for the single GPU node.
- Hardened the k3s server role to reject the placeholder token, set `tls-san`, fetch kubeconfig with `0600` source mode, rewrite the fetched kubeconfig endpoint to the node address, and label the single server as a GPU node.
- Disabled host-side NVIDIA Container Toolkit installation by default so GPU Operator owns toolkit/runtime integration.
- Added Flux-compatible NVIDIA GPU Operator HelmRepository and HelmRelease manifests under `infrastructure/nvidia-gpu-operator`.
- Updated `playbooks/04-flux.yml` and the `flux` role to install Flux controllers from the local control machine and apply `clusters/gpu-cluster`.
- Pinned NVIDIA GPU Operator chart version `v26.3.3`.
- Configured GPU Operator values for operator-managed driver, toolkit, device plugin, GPU Feature Discovery, DCGM exporter, MIG `single`, and k3s containerd integration.
- Added live validation scripts for node readiness, GPU Operator health/GPU allocatable resources, and the NVIDIA runtime test pod.
- Added `scripts/run-static-checks.sh` as the local static gate for Ansible syntax, kustomize render, shell syntax, and inventory graph checks.
- Added `doc/backup-recovery.md` covering kubeconfig regeneration, encrypted vault backup, k3s server data, Flux state, and GPU workload recovery checks.
- Generated a compliant local `vault_k3s_token` and stored it only in the ignored encrypted Ansible Vault file.
- Ran base OS provisioning successfully on `gpu-cp01`; swap is disabled, kernel modules/sysctls are configured, and `iscsid` is enabled.
- Confirmed the node is a KVM host, not a guest, and updated the common role to skip `qemu-guest-agent` service management unless the target is a virtual guest.
- Installed k3s `v1.31.6+k3s1` on `limbo-gpu-001` and fetched the local ignored kubeconfig.
- Installed Flux controllers with `playbooks/04-flux.yml` and applied `clusters/gpu-cluster`.
- Reconciled NVIDIA GPU Operator `v26.3.3` through Flux.

## Verified

- `uv run ansible-playbook -i inventory/gpu-cluster/hosts.yml playbooks/site.yml --syntax-check`
- `uv run ansible-playbook -i inventory/gpu-cluster/hosts.yml playbooks/00-preflight.yml --syntax-check --vault-password-file=.vault_pass`
- `uv run ansible-playbook -i inventory/gpu-cluster/hosts.yml playbooks/04-flux.yml --syntax-check`
- `uv run ansible-playbook -i inventory/gpu-cluster/hosts.yml playbooks/site.yml --syntax-check --vault-password-file=.vault_pass`
- `uv run ansible-playbook -i inventory/gpu-cluster/hosts.yml playbooks/04-flux.yml --syntax-check --vault-password-file=.vault_pass`
- `kubectl kustomize clusters/gpu-cluster`
- `kubectl kustomize infrastructure/nvidia-gpu-operator`
- `sh -n scripts/check-gpu-operator.sh && sh -n scripts/check-gpu-runtime-test.sh && sh -n scripts/check-k3s.sh && sh -n scripts/edit-vault.sh`
- `scripts/run-static-checks.sh`
- `uv run ansible-playbook -i inventory/gpu-cluster/hosts.yml playbooks/00-preflight.yml --vault-password-file=.vault_pass`
- `uv run ansible-playbook -i inventory/gpu-cluster/hosts.yml playbooks/01-base.yml --vault-password-file=.vault_pass`
- `uv run ansible-playbook -i inventory/gpu-cluster/hosts.yml playbooks/02-gpu-runtime.yml --vault-password-file=.vault_pass`
- `uv run ansible-playbook -i inventory/gpu-cluster/hosts.yml playbooks/03-k3s.yml --vault-password-file=.vault_pass`
- `uv run ansible-playbook -i inventory/gpu-cluster/hosts.yml playbooks/04-flux.yml --vault-password-file=.vault_pass`
- `uv run ansible-playbook -i inventory/gpu-cluster/hosts.yml playbooks/site.yml --vault-password-file=.vault_pass`
- `KUBECONFIG_PATH=kubeconfig-gpu-cluster.yaml scripts/check-k3s.sh`
- `KUBECONFIG_PATH=kubeconfig-gpu-cluster.yaml scripts/check-gpu-operator.sh`
- `KUBECONFIG_PATH=kubeconfig-gpu-cluster.yaml scripts/check-gpu-runtime-test.sh`
- `uv run ansible-inventory -i inventory/gpu-cluster/hosts.yml --graph`
- Local `inventory/gpu-cluster/group_vars/gpu_cluster/vault.yml` is present and reports as `Ansible Vault, version 1.1, encryption AES256`; it remains ignored by Git.
- Updated `ansible.cfg` from the removed `community.general.yaml` callback to `ansible.builtin.default` with YAML result formatting.
- Scanned for standalone NVIDIA device-plugin manifests; only policy/status documentation references remain.
- After adding vaulted `vault_ansible_user`, live preflight succeeded: Ubuntu 24.04, kernel `6.17.0-35-generic`, Secure Boot disabled, swap `0`, k3s active, kubeconfig present.
- k3s node readiness passed for `limbo-gpu-001` at `192.168.8.130`.
- Flux controllers are running in `flux-system`.
- GPU Operator HelmRepository is ready and HelmRelease reports `Helm install succeeded for release gpu-operator/gpu-operator.v1 with chart gpu-operator@v26.3.3`.
- GPU Operator ClusterPolicy is `ready`.
- GPU Operator pods are healthy; node allocatable includes `nvidia.com/gpu: 1`.
- NVIDIA runtime test pod completed and logged `NVIDIA-SMI 580.126.20`, `Driver Version: 580.126.20`, and `NVIDIA GeForce RTX 4090`.
- Deleted the completed `default/nvidia-runtime-test` pod after validation; `scripts/check-gpu-runtime-test.sh` recreates it when needed.

## Open Items

- Decide Flux remote, branch, path, and deploy key flow.
- Optional: configure a persistent GitRepository/Kustomization source after the remote and deploy key are known.

## Risks

- GPU Operator installed and manages the NVIDIA driver/runtime stack. Do not add host-side NVIDIA driver or standalone device-plugin management unless requirements change.
- `kubeconfig-gpu-cluster.yaml`, `.vault_pass`, and the encrypted local vault file remain local operational artifacts and must not be committed.

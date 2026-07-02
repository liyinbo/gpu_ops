# Implementation Status

## Current Status

Date: 2026-07-02

The initial repository scaffold exists at `~/repo/gpu_ops`. The repo contains Ansible playbooks and roles for base OS preparation, GPU host prerequisite preparation, k3s server/agent installation, and a Flux placeholder role. NVIDIA GPU Operator is now the selected GPU resource management layer.

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

## Verified

- `uv run ansible-playbook -i inventory/gpu-cluster/hosts.yml playbooks/site.yml --syntax-check`
- `uv run ansible-playbook -i inventory/gpu-cluster/hosts.yml playbooks/04-flux.yml --syntax-check`
- `kubectl kustomize clusters/gpu-cluster`

## Open Items

- Replace placeholder inventory IPs, hostnames, and `ansible_user` with real values.
- Create the encrypted `inventory/gpu-cluster/group_vars/gpu_cluster/vault.yml` file with real values.
- Confirm target OS version and GPU models.
- Decide NVIDIA GPU Operator driver mode: operator-managed driver or preinstalled host driver.
- Add an NVIDIA GPU Operator GitOps entry point.
- Decide GPU Operator Helm values for driver, toolkit, device plugin, GPU feature discovery, MIG, DCGM, and runtime integration.
- Decide Flux remote, branch, path, and deploy key flow.
- Validate actual k3s install on hardware.
- Validate GPU test pod on real GPU nodes.

## Risks

- GPU Operator support and driver behavior can vary by Ubuntu version, kernel, GPU model, and secure boot state.
- The sample k3s version may need to be adjusted to match the target environment.
- RuntimeClass and containerd configuration must match the GPU Operator toolkit/runtime configuration.

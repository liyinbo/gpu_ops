# Implementation Roadmap

## Phase 1: Repository Scaffold

- Create the repository structure.
- Add Ansible config, collection requirements, and Python project metadata.
- Add `AGENTS.md`, `README.md`, and documentation control files.
- Add sample inventory and group vars.

## Phase 2: Base Host Provisioning

- Add a non-destructive preflight check for inventory shape, SSH access, host OS, Secure Boot, current NVIDIA driver visibility, and current k3s state.
- Implement common OS preparation.
- Disable swap.
- Configure Kubernetes kernel modules and sysctls.
- Enable required services such as `iscsid`.

## Phase 3: k3s Installation

- Implement k3s server role.
- Implement k3s agent role.
- Fetch kubeconfig from the first server.
- Add syntax checks for all playbooks.

## Phase 4: GPU Operator Prerequisites

- Confirm target GPU models, host OS version, and current driver state.
- Use operator-managed driver and container toolkit as the default deployment mode.
- Keep host Ansible work limited to prerequisites required by the selected GPU Operator mode.

## Phase 5: GitOps Add-ons

- Add Flux-compatible cluster entry point.
- Add NVIDIA GPU Operator manifests.
- Configure GPU Operator values for operator-managed driver, toolkit, device plugin, GPU feature discovery, DCGM exporter, MIG strategy, and k3s containerd integration.
- Add future infrastructure add-ons as requirements are clarified.

## Phase 6: Validation

- Validate Ansible syntax.
- Render kustomize entry points.
- Confirm k3s node readiness.
- Confirm GPU Operator pods and ClusterPolicy are healthy.
- Run the NVIDIA runtime test pod.
- Capture test results in `doc/platform/implement-status.md`.

## Phase 7: Hardening

- Move real tokens to Ansible Vault or SOPS.
- Add host-specific inventory after hardware is known.
- Add backup and recovery notes for kubeconfig, Flux state, and GPU workload state.

# Requirements

## Scope

Provision and operate a small k3s cluster for GPU workloads using Ansible for host setup and FluxCD-compatible manifests for cluster add-ons. NVIDIA GPU Operator is the selected GPU resource management layer.

## Functional Requirements

### REQ-GPU-001 Base OS Preparation

All GPU cluster nodes must be configured with common operational packages, swap disabled, Kubernetes kernel modules loaded, and Kubernetes networking sysctls applied.

### REQ-GPU-002 k3s Control Plane

The repo must provide an idempotent Ansible path to install and start k3s server nodes.

### REQ-GPU-003 k3s GPU Workers

The repo must provide an idempotent Ansible path to install and start k3s agent nodes labeled for GPU scheduling.

### REQ-GPU-004 GPU Host Prerequisites

GPU worker nodes must be prepared for NVIDIA GPU Operator. Host preparation must stay minimal and must not duplicate GPU Operator responsibilities unless the selected operator deployment mode explicitly requires host-side prerequisites.

### REQ-GPU-005 GitOps Entry Point

The repo must include a Flux-compatible cluster entry point under `clusters/gpu-cluster`.

### REQ-GPU-006 NVIDIA GPU Operator

The repo must include Flux-compatible manifests to install NVIDIA GPU Operator. GPU Operator is responsible for Kubernetes GPU resource management, including device plugin integration and related NVIDIA components.

### REQ-GPU-007 Validation

The repo must include test manifests and commands that verify node readiness, GPU Operator health, GPU discovery, and a GPU test pod.

## Operational Requirements

- Do not store real tokens, private keys, kubeconfigs, or host-specific secrets in Git.
- Store the GPU node become password in Ansible Vault as `vault_ansible_become_password`.
- Store the k3s token in Ansible Vault as `vault_k3s_token`.
- Keep host inventory examples clearly replaceable.
- Run Ansible syntax checks before applying playbooks to real hosts.
- Run manifest rendering checks before committing GitOps changes.
- Document known blockers and incomplete work in `doc/implement-status.md`.

## Out Of Scope

- Automated Flux bootstrap against a remote Git provider before the remote and deploy key are known.
- Standalone NVIDIA device plugin management outside GPU Operator.
- Production workload scheduling policy until real GPU hardware and workload requirements are known.

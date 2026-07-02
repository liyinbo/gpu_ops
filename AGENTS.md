# GPU Ops

## Project Overview

GPU-focused Kubernetes operations repo for provisioning Ubuntu GPU nodes, installing k3s, and managing GPU resources with NVIDIA GPU Operator through GitOps.

## Documentation

All project documentation and planning documents MUST be placed in the `doc/` folder. Do not create markdown files or documentation outside of `doc/`, except this file and `README.md`.

The repo is driven by these control documents:

- `doc/requirements.md` - source of truth for functional and operational requirements.
- `doc/implement-roadmap.md` - ordered implementation plan.
- `doc/implement-status.md` - current progress, decisions, and open blockers.
- `doc/test-cases.md` - validation and acceptance test matrix.

When making implementation changes, update the relevant control document in the same change. Keep status factual and dated.

## Project Structure

- `inventory/` - Ansible inventory and group variables
- `playbooks/` - Ansible playbooks for base OS, k3s, GPU runtime, and full site runs
- `roles/` - Ansible roles for common host setup, k3s server/agent, GPU host prerequisites, and Flux
- `clusters/` - FluxCD cluster entrypoints
- `infrastructure/` - GitOps infrastructure manifests
- `apps/` - GitOps applications and workloads
- `tests/` - Kubernetes test manifests
- `scripts/` - Operational helper scripts
- `doc/` - Project documentation, requirements, roadmap, status, and test cases

## Operating Notes

- Keep inventory hostnames, IPs, users, and tokens out of committed examples unless they are safe placeholders.
- Store secrets in Ansible Vault or SOPS, not plaintext YAML.
- Run syntax checks before applying playbooks to real hosts.
- Prefer idempotent Ansible tasks over ad hoc shell scripts.
- Do not make destructive GPU driver, CUDA, or k3s changes without first checking current host state.
- Treat placeholder inventory values as examples only; verify real hostnames, IPs, SSH users, GPU models, and OS versions before running playbooks.
- NVIDIA GPU Operator is the intended owner for Kubernetes GPU resources. Do not add standalone NVIDIA device plugin management unless `doc/requirements.md` is updated to change that decision.

## Default Workflow

Run syntax checks:

```bash
uv run ansible-playbook -i inventory/gpu-cluster/hosts.yml playbooks/site.yml --syntax-check
```

Run phased provisioning:

```bash
uv run ansible-playbook -i inventory/gpu-cluster/hosts.yml playbooks/01-base.yml
uv run ansible-playbook -i inventory/gpu-cluster/hosts.yml playbooks/02-gpu-runtime.yml
uv run ansible-playbook -i inventory/gpu-cluster/hosts.yml playbooks/03-k3s.yml
```

# Backup and Recovery

## Local Operator Artifacts

- Keep `.vault_pass`, `inventory/gpu-cluster/group_vars/gpu_cluster/vault.yml`, and `kubeconfig-gpu-cluster.yaml` out of Git.
- Store the vault password in the operator's password manager.
- Store a backup copy of the encrypted vault file in the approved secrets backup location.
- Regenerate `kubeconfig-gpu-cluster.yaml` by rerunning `playbooks/03-k3s.yml` after host access and vault access are available.

## k3s Server

- Back up `/var/lib/rancher/k3s/server/db` before destructive k3s maintenance.
- Record the installed `k3s_version` from `inventory/gpu-cluster/group_vars/all.yml` before upgrade or restore work.
- Restore onto the same or a compatible k3s version before reconciling Flux.

## Flux State

- Treat Git as the source of truth for `clusters/gpu-cluster` and `infrastructure/`.
- Re-bootstrap Flux only after the Git remote, branch, path, and deploy key are confirmed.
- After restore, run `kubectl kustomize clusters/gpu-cluster` locally, then reconcile the Flux Kustomization on the cluster.

## GPU Workload State

- Back up persistent workload data at the storage layer used by the workload.
- Capture workload manifests and Helm values in Git before deployment.
- After recovery, validate GPU Operator health before restoring GPU workloads.
- Run `scripts/check-gpu-operator.sh` and `tests/nvidia-runtime-test.yaml` before declaring GPU scheduling recovered.

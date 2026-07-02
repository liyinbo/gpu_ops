# Bootstrap

1. Update `inventory/gpu-cluster/hosts.yml` with real hosts.
2. Create a local `.vault_pass` file for the Ansible Vault password.
3. Create encrypted `inventory/gpu-cluster/group_vars/gpu_cluster/vault.yml` with `scripts/edit-vault.sh`.
4. Store `vault_ansible_user`, `vault_ansible_become_password`, and `vault_k3s_token` in that encrypted vault file.
5. Confirm SSH authentication for the vaulted `vault_ansible_user`. For key auth, set `GPU_OPS_SSH_KEY` to a local private key path. For password auth, store `vault_ansible_password` in the encrypted vault file.
6. Run static checks with `scripts/run-static-checks.sh`.
7. Run `playbooks/00-preflight.yml` with `--vault-password-file=.vault_pass`.
8. Run `playbooks/site.yml` with `--vault-password-file=.vault_pass`.
9. Install Flux controllers and reconcile `clusters/gpu-cluster` with `playbooks/04-flux.yml`.
10. Verify GPU Operator health.
11. Validate GPU scheduling with `tests/nvidia-runtime-test.yaml`.

Vault file content:

```yaml
vault_ansible_become_password: your-gpu-node-sudo-password
vault_ansible_user: your-gpu-node-ssh-user
# vault_ansible_password: your-gpu-node-ssh-password
vault_k3s_token: your-long-random-k3s-token
```

The real `vault.yml` is ignored by Git to avoid accidentally committing plaintext. The committed `vault.yml.example` shows the required variable names.

The default GPU Operator mode is operator-managed driver and toolkit installation. If the target host already has a validated NVIDIA driver or container toolkit, update `infrastructure/nvidia-gpu-operator/helmrelease.yaml` before reconciliation and record the reason in `doc/implement-status.md`.

See `doc/ssh-access.md` when preflight fails before host facts are gathered.

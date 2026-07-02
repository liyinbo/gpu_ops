# Bootstrap

1. Update `inventory/gpu-cluster/hosts.yml` with real hosts.
2. Create a local `.vault_pass` file for the Ansible Vault password.
3. Create encrypted `inventory/gpu-cluster/group_vars/gpu_cluster/vault.yml` with `scripts/edit-vault.sh`.
4. Store `vault_ansible_become_password` and `vault_k3s_token` in that encrypted vault file.
5. Run syntax checks with `--vault-password-file=.vault_pass`.
6. Run `playbooks/site.yml` with `--vault-password-file=.vault_pass`.
7. Add NVIDIA GPU Operator manifests and values for the target hardware.
8. Reconcile `clusters/gpu-cluster` with Flux after Flux is bootstrapped.
9. Verify GPU Operator health.
10. Validate GPU scheduling with `tests/nvidia-runtime-test.yaml`.

Vault file content:

```yaml
vault_ansible_become_password: your-gpu-node-sudo-password
vault_k3s_token: your-long-random-k3s-token
```

The real `vault.yml` is ignored by Git to avoid accidentally committing plaintext. The committed `vault.yml.example` shows the required variable names.

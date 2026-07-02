# GPU Ops

Ansible and GitOps operations for a single-node k3s GPU cluster managed with NVIDIA GPU Operator.

The current inventory target is `gpu-cp01` at `192.168.8.130`. Secrets and local operational artifacts are intentionally ignored by Git, including `.vault_pass`, encrypted `vault.yml`, and fetched kubeconfigs.

Start with the bootstrap flow:

```bash
scripts/edit-vault.sh
scripts/run-static-checks.sh
uv run ansible-playbook -i inventory/gpu-cluster/hosts.yml playbooks/00-preflight.yml --vault-password-file=.vault_pass
```

Documentation starts at `doc/README.md`.

- Platform control docs: `doc/platform/`
- Platform runbooks: `doc/platform/runbooks/`
- Task control docs: `doc/tasks/<task>/`
- TTS task docs: `doc/tasks/tts/`

For platform operations, use `doc/platform/runbooks/bootstrap.md` and `doc/platform/runbooks/ssh-access.md`.

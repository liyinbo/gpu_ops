# SSH Access

The configured single GPU node is `gpu-cp01` at `192.168.8.130`.

## Key-Based Access

Set the SSH username in the encrypted vault file:

```yaml
vault_ansible_user: your-gpu-node-ssh-user
```

Use key-based SSH when possible:

```bash
export GPU_OPS_SSH_KEY=/path/to/private/key
uv run ansible-playbook -i inventory/gpu-cluster/hosts.yml playbooks/00-preflight.yml --vault-password-file=.vault_pass
```

`GPU_OPS_SSH_KEY` is read locally by Ansible and must not be committed.

## Password-Based Access

Use password-based SSH only when key auth is unavailable. Store the SSH password in the ignored encrypted vault file:

```yaml
vault_ansible_password: your-gpu-node-ssh-password
```

Then run:

```bash
uv run ansible-playbook -i inventory/gpu-cluster/hosts.yml playbooks/00-preflight.yml --vault-password-file=.vault_pass
```

## Current Failure Signature

The current live preflight reaches SSH but fails authentication:

```text
Permission denied (publickey,password)
```

Fix one of these before running provisioning:

- `ansible_user` in `inventory/gpu-cluster/group_vars/all.yml`
- encrypted `vault_ansible_user`
- local `GPU_OPS_SSH_KEY`
- encrypted `vault_ansible_password`
- allowed keys or password authentication on `192.168.8.130`

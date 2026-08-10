# Initialize and Unseal Development Vault

## Initialize Once

Choose an absolute path outside the repository on encrypted operator storage:

```bash
scripts/vault/check-health.sh --expect-uninitialized
scripts/vault/initialize.sh /secure/operator/path/gpu-vault-init.json
scripts/vault/check-health.sh
```

The output contains the single unseal key and initial root token. Import it into the approved
password manager and remove the local file. Never commit, paste, or send its contents.

## Unseal After Restart

Retrieve only the unseal key from the password manager, then run:

```bash
kubectl --kubeconfig kubeconfig-gpu-cluster.yaml -n vault exec -it vault-0 -- \
  vault operator unseal
```

Enter the key only at the hidden prompt. Confirm health with
`scripts/vault/check-health.sh`.

## Limitations

This deployment is single-node development infrastructure. Loss of the node or local volume
requires restore from an independently protected snapshot, which is not yet configured.

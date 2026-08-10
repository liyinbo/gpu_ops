# Development Vault Test Cases

## Static Checks

### TC-VAULT-001 Manifest Render

```bash
kubectl kustomize apps/vault >/tmp/gpu-ops-vault-render.yaml
```

Expected: manifests render with a pinned chart/image, standalone persistent storage, internal
TLS, and no external service or ingress.

### TC-VAULT-002 Repository Static Gate

```bash
scripts/run-static-checks.sh
```

Expected: repository static checks pass, including Vault rendering and helper syntax.

## Runtime Checks

### TC-VAULT-010 Pre-initialization Gate

```bash
scripts/vault/check-health.sh --expect-uninitialized
```

Expected: Vault is reachable over its mounted CA, reports initialized false and sealed true.

### TC-VAULT-020 Initialized Health

```bash
scripts/vault/check-health.sh
```

Expected: Vault reports initialized true and sealed false.

### TC-VAULT-030 Isolation

Expected: Vault Services are ClusterIP, no Ingress exists, and NetworkPolicy allows TCP 8200
only from `meta-harness`.

### TC-VAULT-040 Persistence

Expected: the data PVC is Bound through `vault-local`, whose reclaim policy is `Retain`.

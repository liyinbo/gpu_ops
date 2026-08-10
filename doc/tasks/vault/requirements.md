# Development Vault Requirements

## Scope

Deploy a simple, single-node HashiCorp Vault for development workloads on the GPU cluster.
This Vault is separate from the production storage-cluster Vault and must not contain or
receive production credentials.

## Requirements

### REQ-VAULT-001 Persistent Standalone Deployment

Vault must run in standalone mode with persistent local storage and retained volumes. Vault
dev mode is prohibited because it stores data only in memory and embeds an unsafe root token.

### REQ-VAULT-002 Internal TLS

Vault must use cert-manager-managed private-CA TLS. It must have no Ingress, LoadBalancer, or
NodePort.

### REQ-VAULT-003 Network Isolation

Default-deny networking must restrict Vault API ingress to the `meta-harness` namespace.

### REQ-VAULT-004 Manual Seal Custody

The development deployment may use one Shamir share with a threshold of one. Initialization
material must be written only to an operator-selected path outside the repository, protected
mode 0600, and transferred to the approved password manager.

### REQ-VAULT-005 Separate Trust Boundary

No production Vault token, unseal share, root token, policy, credential, or KV record may be
copied into this development Vault.

### REQ-VAULT-006 GitOps Ownership

Flux must own the namespace, dedicated retained StorageClass, certificate resources, network
policies, Helm source, and pinned HelmRelease.

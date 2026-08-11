# Next Goal: Development Vault Integration

Paste this into a new session from `/Users/limbo/repo/gpu_ops`:

```text
/goal Implement and deploy the same-cluster development Vault integration for Meta Harness.

Read AGENTS.md and all four control documents under doc/tasks/meta-harness/, then follow
doc/tasks/meta-harness/runbooks/vault-integration.md exactly. Use the existing GPU-cluster
Vault only; never connect to storage_server_ops Vault or copy production secret material.

Add a separately managed retained audit PVC and mount it without changing the existing
StatefulSet volumeClaimTemplates. Account for the OnDelete restart and operator unseal. Add an
idempotent bootstrap for the meta-harness-dev KV v2 mount, exact-path read-only policy, and
same-cluster Kubernetes auth role bound to
meta-harness/meta-harness-workspace-broker with audience vault. Extend secret bootstrap to
copy only Vault's public CA into meta-harness. Upgrade Meta Harness to chart 0.3.1 while
keeping image a1e8cf7, configure authRole with no static token, and allowlist only the
synthetic credential-resolve reference. Do not configure pushCredentialReference or ingest a
real Git credential.

Commit, push, reconcile Flux, and do not stop at green pods: preload a short-lived synthetic
record, prove exact resolution plus wrong-target/scope/reference/path denials, and confirm
auth/kubernetes/login in the persistent Vault audit log without printing secret values. Rerun
the existing Meta Harness and repository checks, update factual dated status/test evidence,
and leave the working tree clean. If the root token or unseal key is required, pause for the
operator to enter it through a hidden TTY prompt; never request it in chat or place it in an
argument, environment variable, repository file, or Kubernetes Secret.
```

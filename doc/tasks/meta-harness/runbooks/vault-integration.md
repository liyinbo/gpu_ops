# Integrate Meta Harness with Development Vault

## Boundary and Current State

Use only the standalone Vault at `https://vault.vault.svc:8200` in the GPU cluster. Do not
expose or connect to the production storage-cluster Vault. Do not copy production credentials,
tokens, policies, unseal shares, root tokens, or KV records.

As of 2026-08-11, development Vault is initialized, unsealed, TLS-enabled, persistent, and
reachable only through ClusterIP services. Meta Harness is healthy on chart `0.3.0` and image
`a1e8cf7`, with no Vault configuration. Chart `0.3.1` is published and adds the configurable
Kubernetes auth mount; use it while retaining image `a1e8cf7`.

Post-integration note (2026-08-11): image `68904ca` superseded `a1e8cf7` to complete the
browser Authentik handoff, then image `2bc9223` disabled local authentication in both the UI
and API. Neither changes the Vault values or credential boundary below.

## Stage 1: Persistent Audit Storage

Create a separately managed 1 GiB `vault-audit` PVC on `vault-local`, then add that existing
claim to the HelmRelease's `server.volumes` and mount it at `/vault/audit`. Do not turn on the
chart's `auditStorage` value after installation: that adds a StatefulSet
`volumeClaimTemplate`, which is immutable on the existing StatefulSet and makes the Helm
upgrade fail. A separate claim keeps the audit log away from the Vault data PVC and changes
only the mutable pod template.

The release uses `OnDelete`, so after Flux applies the new template, deliberately recreate
`vault-0`, wait for it to return sealed, and have the operator enter the unseal key through
the hidden TTY prompt. Verify healthy state before enabling the audit device.

Use the operator-held initial root token only through a hidden prompt for this bootstrap. Do
not put it in an argument, environment variable, repository file, Kubernetes Secret, or chat.
Enable the file audit device at `/vault/audit/audit.log`, verify it is listed, then remove any
ephemeral CLI token cache from the pod.

## Stage 2: Mount, Policy, and Kubernetes Auth

Create KV v2 mount `meta-harness-dev/`. Install policy
`meta-harness-workspace-broker-dev` with only:

```hcl
path "meta-harness-dev/data/tests/credential-resolve" {
  capabilities = ["read"]
}
```

Enable the default `kubernetes/` auth mount. Configure it against
`https://kubernetes.default.svc:443` with the pod ServiceAccount CA. The Vault HelmRelease
already creates an auth-delegator ServiceAccount and NetworkPolicy already permits the API
service on TCP 443.

Create this role:

```text
auth mount: kubernetes
role: meta-harness-workspace-broker-dev
bound ServiceAccount: meta-harness-workspace-broker
bound namespace: meta-harness
audience: vault
policy: meta-harness-workspace-broker-dev
token TTL: 20m
token max TTL: 1h
```

Make bootstrap idempotent and commit policy source under `apps/vault/policies/`; do not commit
tokens or secret values.

## Stage 3: Public CA Secret

Extend `apps/meta-harness/bootstrap-secrets.sh` to copy only `ca.crt` from
`vault/vault-server-tls` into `meta-harness/meta-harness-vault-ca`. Use an in-memory or
mode-0600 temporary file, never print the certificate's private-key fields, and never copy
`tls.key` or the CA signing Secret.

## Stage 4: Helm Values

Upgrade `apps/meta-harness/helmrelease.yaml` to chart `0.3.1`, retain image `a1e8cf7`, and add:

```yaml
vault:
  enabled: true
  url: https://vault.vault.svc:8200
  mount: meta-harness-dev
  authRole: meta-harness-workspace-broker-dev
  authMount: kubernetes
  referencesJson: '{"vault:tests/credential-resolve":"tests/credential-resolve"}'
  ca:
    existingSecret: meta-harness-vault-ca
    key: ca.crt
    mountPath: /var/run/meta-harness/vault-ca
```

Do not set `vault.existingSecret`. Do not set `pushCredentialReference` during this stage.

## Stage 5: Synthetic Record and Proof

Preload this record at `meta-harness-dev/tests/credential-resolve` using an operator session:

```json
{
  "username": "vault-dev-test",
  "secret": "<new random non-production value>",
  "host": "forgejo.invalid",
  "repository": "limbo/non-production.git",
  "scope": "read",
  "expiresAt": "<short future RFC 3339 timestamp>",
  "revoked": false
}
```

Port-forward the internal workspace-broker and POST to `/credentials/resolve` with the exact
reference, host, repository, and scope. Assert the username and that a non-empty secret was
returned without printing the secret. Repeat with a wrong host, repository, scope, unknown
reference, and sibling Vault path; all must fail closed.

Confirm the audit log contains `auth/kubernetes/login` for
`meta-harness-workspace-broker-dev`. A green broker pod alone is not evidence because the
Vault client is constructed per request.

Finally rerun static checks, Flux/Helm readiness, all seven Meta Harness pod checks, HTTPS,
OIDC routing, local-auth denial, node connectivity, and an approved `git.commit`.

## Deferred Push Credential

Do not ingest a real Forgejo token or enable `pushCredentialReference` in this implementation.
That requires a separate decision about the exact Git host, repository metadata, token scope,
expiration, rotation, revocation, and the branch allowed for development pushes.

## Stage 6: Agent Provider Credentials

Keep the workspace-broker policy, role, and synthetic reference unchanged. Apply the two
additional exact-path policies and Kubernetes roles with restricted operator OIDC.

First, an Authentik administrator adds the intended human operator to `Vault GPU Operators`.
Do not add users declaratively or broaden the group binding. Then initialize Vault OIDC once:

```sh
scripts/vault/bootstrap-operator-oidc.sh
```

This is the only step that accepts the Vault initial root token. Enter it only through the
script's hidden TTY prompt. The script enables the `oidc/` auth mount, streams the generated
client secret from the Authentik blueprint Secret directly into Vault through stdin, and
creates a group-bound role whose policy can manage only the
two provider policy documents and two provider Kubernetes roles. It removes the root CLI
token cache when it exits. It does not access the storage-cluster Vault or copy any of its
material; the only cross-cluster value is this dedicated OIDC client secret.

For routine provider policy and role reconciliation, run:

```sh
scripts/vault/bootstrap-meta-harness-providers.sh
```

The script starts a temporary localhost callback port-forward and prints an Authentik login
URL. Complete browser sign-in as a `Vault GPU Operators` member. The resulting short-lived
Vault token is cached only inside `vault-0`, is used to configure the exact resources below,
and is removed when the script exits:

- `meta-harness-credential-ingest`: create/update only on
  `meta-harness-dev/data/providers/claude`.
- `meta-harness-worker`: read only on the same exact path.
- separate Kubernetes roles bound to the corresponding `meta-harness` ServiceAccounts with
  audience `vault`.

Validate the OIDC token cannot read `meta-harness-dev/data/*`, change `sys/mounts` or
`sys/auth`, change the workspace-broker policy or role, or create an unrelated policy. Do not
use this identity with `storage_server_ops` Vault.

After chart `0.3.3` reconciles, an administrator opens the Vault tool and stores the provider
key using provider id `claude-live` and reference path `providers/claude`. The key must be
entered only in that password field, never in this runbook, a shell argument, environment
variable, Git, SOPS, or a Kubernetes Secret. The first provider run raises the expected
high-risk grant for `brain:claude-live`; approve it and retry. Confirm a real answer and the
two distinct `auth/kubernetes/login` records in `/vault/audit/audit.log` without printing the
key or Vault response bodies that contain it.

# Meta Harness Development Instance Requirements

## Scope

Operate the Meta Harness development instance on the GPU cluster at
`meta-harness-dev.home.hope-leniency.com`. The reusable application image and Helm chart are
published separately; this repository owns the cluster-specific Flux release, development
PostgreSQL instance, ingress values, node workspace storage, and secret bootstrap procedure.

## Functional Requirements

### REQ-MH-001 GitOps Deployment

The instance must be deployed through Flux from the manifests under `apps/meta-harness` and
must pin a published Helm chart version and application image tag.

### REQ-MH-002 Writable Temporary Storage

All application components must have writable temporary storage while retaining a read-only
root filesystem, so approved Git operations such as `git.commit` can complete.

### REQ-MH-003 Development Execution Node

The in-cluster node agent must own workspace storage on a persistent `local-path` volume and
provide the configured file, patch, shell, web, and Git tools over its relay channel.

### REQ-MH-004 Authentication

The instance must support Authentik OIDC through the provider shared with the production
instance. Local profile authentication must remain enabled as a recovery path. The OIDC
client secret must not be committed in plaintext.

### REQ-MH-005 Development Database

The instance may use a single-replica PostgreSQL StatefulSet backed by `local-path`; its
recreatable development data does not require production HA.

### REQ-MH-006 Private HTTPS

The instance must be exposed through Traefik and cert-manager at
`https://meta-harness-dev.home.hope-leniency.com` on the GPU node ingress address.

### REQ-MH-007 Development Vault Isolation

Meta Harness credential-broker testing must use the standalone Vault in the GPU cluster. It
must not connect to the production Vault or copy production credentials, tokens, policies,
unseal material, or KV records.

### REQ-MH-008 Workload Identity

The workspace broker must authenticate to development Vault through the same-cluster
Kubernetes auth mount using a projected ServiceAccount token with audience `vault`. A static
Vault token must not be mounted into Meta Harness.

### REQ-MH-009 Least-Privilege Credential Resolution

The first integration must allow the broker to read exactly one synthetic, non-production KV
v2 record. The policy must not list the mount or access sibling paths. No
`pushCredentialReference` may be configured until credential resolution and denial tests pass.

### REQ-MH-010 Private CA Trust

Only Vault's public CA certificate may be copied into the `meta-harness` namespace. Vault CA
private keys and server private keys must remain in `vault`.

## Operational Requirements

- Create runtime, registry, chart repository, and OIDC secrets with
  `apps/meta-harness/bootstrap-secrets.sh`; do not commit their values.
- Deploy the matching Authentik provider and callback registration from
  `storage_server_ops` before enabling the development OIDC client.
- Preserve `readOnlyRootFilesystem`; writable `/tmp` must come from chart-managed scratch
  volumes rather than weakening the container security context.
- Do not treat development database or workspace volumes as production-grade HA storage.
- Keep the development Vault sealed-state recovery material in the approved password manager;
  never expose it to Meta Harness.

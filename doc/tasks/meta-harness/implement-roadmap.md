# Meta Harness Development Instance Implementation Roadmap

## Phase 1: Base Deployment

- [x] Add the namespace, development PostgreSQL StatefulSet, Helm repository, and HelmRelease.
- [x] Configure the in-cluster execution node and persistent workspace volume.
- [x] Configure private HTTPS ingress for the development hostname.
- [x] Add an idempotent bootstrap procedure for uncommitted secrets.

## Phase 2: Git Operation Reliability

- [x] Pin chart `0.3.1`, which includes the writable `/tmp` scratch volumes introduced in
  `0.2.3` while preserving
  read-only root filesystems.
- [x] Re-run the approved patch, stage, and `git.commit` workflow against the reconciled
  `0.3.1` release.

## Phase 3: OIDC

- [x] Configure the shared Authentik issuer, client ID, development callback, and secret
  reference.
- [x] Extend secret bootstrap to create `meta-harness-oidc` from `OIDC_CLIENT_SECRET`.
- [x] Verify the matching Authentik provider and development callback are deployed from
  `storage_server_ops`, and bootstrap the client secret in the GPU cluster.
- [x] Reconcile the release and verify OIDC discovery/login routing.
- [x] Expose configured Authentik sign-in in the browser and redirect a successful OIDC
  callback to the authenticated application shell.
- [x] Disable the local-profile browser controls and reject direct local-auth API requests.
- [ ] Complete one interactive Authentik login and callback with an operator identity.

## Phase 4: Validation and Operations

- [x] Add Kustomize rendering and shell syntax checks to the repository static gate.
- [x] Validate Flux readiness, HTTPS, PostgreSQL readiness, node readiness, and authentication
  routing on the live cluster.
- [x] Re-run the full approved Git workflow on the live cluster.

## Phase 5: Development Vault Integration

- [x] Deploy a separate, internal-only development Vault in the GPU cluster.
- [x] Add a separately managed retained persistent claim for Vault audit storage and mount it
  without modifying the StatefulSet claim templates.
- [x] Enable the file audit device after the `OnDelete` restart and operator unseal.
- [x] Enable a `meta-harness-dev/` KV v2 mount and the same-cluster `kubernetes/` auth mount.
- [x] Commit an idempotent bootstrap and exact read-only policy source for
  `meta-harness-dev/data/tests/credential-resolve`, to be applied and bound
  to `meta-harness/meta-harness-workspace-broker` with audience `vault`.
- [x] Copy only `ca.crt` into an out-of-band `meta-harness-vault-ca` Secret.
- [x] Configure Meta Harness chart `0.3.1`; initially retain image `a1e8cf7`, deploy image
  `68904ca` for the browser Authentik handoff, then image `2bc9223` for enforced OIDC-only auth.
- [x] Configure role-based Vault access without a static token or push credential.
- [x] Preload and resolve a synthetic test record, verify Kubernetes login in the audit log,
  and prove wrong target, wrong scope, unknown reference, and sibling-path access fail closed.
- [x] Remove the obsolete cross-cluster production-Vault handoff after preserving its security
  decision in the task records.

## Phase 6: Vault-Backed Agent Provider

- [x] Publish the Phase 29 application image and chart containing `providers.*` and the
  dedicated credential-ingest and worker identities.
- [x] Add disjoint exact-path policy sources: create/update-only ingest and read-only worker,
  with no list, delete, destroy, repository, or synthetic-test access.
- [x] Add an idempotent hidden-prompt bootstrap for the two same-cluster Kubernetes auth roles.
- [x] Configure the secret-free `claude-live` provider, disable the mock engine, and reuse only
  Vault's existing public CA Secret.
- [ ] Have an administrator store the provider key through the Vault tool and approve the
  first-use grant to `brain:claude-live`.
- [ ] Prove a real provider answer and confirm distinct ingest/worker logins in the retained
  Vault audit log without printing the provider key.

## Phase 7: Restricted Operator OIDC

- [x] Define a confidential Authentik application with one exact localhost callback and a
  dedicated `Vault GPU Operators` group.
- [x] Add an exact Vault operator policy and an idempotent one-time root bootstrap for the
  OIDC auth mount and group-bound role.
- [x] Replace the provider bootstrap root prompt with interactive Authentik OIDC login and
  short-lived token cleanup.
- [x] Permit Vault egress only to the private Authentik HTTPS address in addition to its
  existing DNS and Kubernetes API access.
- [ ] Add the intended human operator to the Authentik group, run the one-time root bootstrap,
  and prove a restricted OIDC login plus denied access outside the four exact management paths.

## Phase 8: Brain-Owned Provider Configuration

- [x] Publish and independently verify Meta Harness chart and linux/amd64 image `0.3.4`.
- [x] Rename the secret-free provider value from `configJson` to the insert-only `seedJson`.
- [x] Allowlist the normalized Anthropic endpoint and operator-approved
  `https://api2.limtok.net` endpoint.
- [x] Reconcile chart `0.3.4` and verify schema `0012_agent_provider_registry`, the seeded
  provider registry, runtime defaults, process allowlists, and absence of provider key fields.
- [ ] Verify an administrator sees Brain provider controls and an adult profile does not.

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

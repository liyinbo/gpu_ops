# Meta Harness Development Instance Implementation Roadmap

## Phase 1: Base Deployment

- [x] Add the namespace, development PostgreSQL StatefulSet, Helm repository, and HelmRelease.
- [x] Configure the in-cluster execution node and persistent workspace volume.
- [x] Configure private HTTPS ingress for the development hostname.
- [x] Add an idempotent bootstrap procedure for uncommitted secrets.

## Phase 2: Git Operation Reliability

- [x] Pin chart `0.3.0`, which includes the writable `/tmp` scratch volumes introduced in
  `0.2.3` while preserving
  read-only root filesystems.
- [ ] Re-run the approved patch, stage, and `git.commit` workflow against the reconciled
  `0.3.0` release.

## Phase 3: OIDC

- [x] Configure the shared Authentik issuer, client ID, development callback, and secret
  reference while retaining local profile authentication.
- [x] Extend secret bootstrap to create `meta-harness-oidc` from `OIDC_CLIENT_SECRET`.
- [x] Verify the matching Authentik provider and development callback are deployed from
  `storage_server_ops`, and bootstrap the client secret in the GPU cluster.
- [x] Reconcile the release and verify OIDC discovery/login routing and local-profile
  recovery.
- [ ] Complete one interactive Authentik login and callback with an operator identity.

## Phase 4: Validation and Operations

- [x] Add Kustomize rendering and shell syntax checks to the repository static gate.
- [x] Validate Flux readiness, HTTPS, PostgreSQL readiness, node readiness, and authentication
  routing on the live cluster.
- [ ] Re-run the full approved Git workflow on the live cluster.

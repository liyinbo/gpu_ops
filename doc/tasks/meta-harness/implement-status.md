# Meta Harness Development Instance Implementation Status

## Current Status

Date: 2026-08-10

The development instance is healthy on Meta Harness chart `0.3.0` and image `a1e8cf7`. The
matching Authentik provider and development callback are live, and the GPU cluster now has the
uncommitted OIDC client secret. The release manifest is ready to enable shared-provider OIDC
while preserving local profile authentication.

## Completed

- Deployed the development instance at `meta-harness-dev.home.hope-leniency.com` using a
  single-replica PostgreSQL StatefulSet and an in-cluster execution node.
- Corrected DNS to the GPU node Traefik address `192.168.8.130`.
- Updated the pinned chart through `0.3.0`; it retains the writable `/tmp` scratch volumes
  introduced in `0.2.3`.
- Added Authentik issuer, client ID, development callback, existing-secret reference, and
  retained local profile authentication.
- Extended `bootstrap-secrets.sh` to apply `meta-harness-oidc` when
  `OIDC_CLIENT_SECRET` is supplied and to report the local-profile fallback when it is not.
- Added Meta Harness manifest rendering and bootstrap shell syntax to the static checks.
- Verified the shared Authentik provider accepts the development callback and copied its
  matching client secret into the GPU cluster as `meta-harness/meta-harness-oidc` without
  committing or printing the value.

## Validation

- `git diff --check`: pass on 2026-08-05.
- `sh -n apps/meta-harness/bootstrap-secrets.sh`: pass on 2026-08-05.
- `kubectl kustomize apps/meta-harness`: pass on 2026-08-05; the rendered HelmRelease
  contains chart `0.2.3` and the expected OIDC issuer, callback, and secret reference.
- `scripts/run-static-checks.sh`: pass on 2026-08-05.
- Pre-OIDC live state on 2026-08-10: HelmRelease ready on chart `0.3.0`, seven application
  pods running, and the application URL returned HTTP 200.

## Open Items

- Reconcile Flux and verify OIDC login, local-profile recovery, and the previously failing
  approved `git.commit` workflow.

## Risks

- OIDC depends on the shared cross-cluster Authentik provider; local profile authentication is
  intentionally retained as a recovery path.
- The development PostgreSQL and node workspace claims use single-node `local-path` storage.
- Chart `0.2.2` was published twice from different trees and must not be selected again.

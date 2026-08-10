# Meta Harness Development Instance Implementation Status

## Current Status

Date: 2026-08-10

The development instance is healthy on Meta Harness chart `0.3.0` and image `a1e8cf7` with
shared-provider OIDC enabled. The matching Authentik provider and development callback are
live, the GPU cluster has the uncommitted OIDC client secret, and local profile authentication
remains enabled as the recovery path.

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
- Committed and reconciled the OIDC configuration at Git revision `8ad687d`.

## Validation

- `git diff --check`: pass on 2026-08-05.
- `sh -n apps/meta-harness/bootstrap-secrets.sh`: pass on 2026-08-05.
- `kubectl kustomize apps/meta-harness`: pass on 2026-08-05; the rendered HelmRelease
  contains chart `0.2.3` and the expected OIDC issuer, callback, and secret reference.
- `scripts/run-static-checks.sh`: pass on 2026-08-05.
- Pre-OIDC live state on 2026-08-10: HelmRelease ready on chart `0.3.0`, seven application
  pods running, and the application URL returned HTTP 200.
- `scripts/run-static-checks.sh`: pass on 2026-08-10 with the OIDC configuration rendered.
- Flux `gpu-ops` source and `gpu-apps` Kustomization: `Ready=True` at
  `main@sha1:8ad687d1` on 2026-08-10.
- Meta Harness HelmRelease: `Ready=True`; Helm upgrade succeeded as revision 4 with chart
  `0.3.0`.
- All seven Meta Harness pods: `Running`, ready, and zero restarts after the OIDC rollout.
- `https://meta-harness-dev.home.hope-leniency.com/app/`: HTTP 200.
- `/auth/oidc/login`: HTTP 307 to the shared Authentik authorization endpoint with the exact
  development callback; API logs show successful OIDC discovery with HTTP 200.
- `/auth/local`: HTTP 200, confirming the local-profile recovery route remains functional.

## Open Items

- Complete one interactive Authentik login/callback with an operator identity; automated
  validation confirmed discovery and the authorization redirect but did not submit credentials.
- Verify the previously failing approved `git.commit` workflow.

## Risks

- OIDC depends on the shared cross-cluster Authentik provider; local profile authentication is
  intentionally retained as a recovery path.
- The development PostgreSQL and node workspace claims use single-node `local-path` storage.
- Chart `0.2.2` was published twice from different trees and must not be selected again.

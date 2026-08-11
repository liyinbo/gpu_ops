# Meta Harness Development Instance Implementation Status

## Current Status

Date: 2026-08-11

The development instance remains healthy on Meta Harness chart `0.3.0` and image `a1e8cf7`
while the chart `0.3.1` same-cluster Vault integration is prepared for reconciliation. The
matching Authentik provider and development callback are live, the GPU cluster has the
uncommitted OIDC client secret, and local profile authentication remains enabled as the
recovery path.

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
- Added a separately managed 1 GiB `vault-audit` claim with retention safeguards and mounted
  it through the Vault pod template without changing `volumeClaimTemplates`.
- Added exact-path policy source and an idempotent, hidden-prompt Vault bootstrap for the KV v2
  mount, file audit device, Kubernetes auth configuration, and broker role.
- Copied only the public `ca.crt` from `vault/vault-server-tls` into the out-of-band
  `meta-harness/meta-harness-vault-ca` Secret; its data contains only the `ca.crt` key.
- Prepared chart `0.3.1` values with image `a1e8cf7`, the dedicated broker identity,
  `authRole=meta-harness-workspace-broker-dev`, and only the synthetic reference allowlist.
  No static Vault token, push credential reference, or real Git credential is configured.
- Configured Kubernetes auth to load the rotating reviewer token and CA directly from the
  Vault pod ServiceAccount projection. Supplying a CA value while omitting the reviewer token
  made Vault fall back to the audience-scoped client JWT for TokenReview and was rejected;
  the bootstrap now explicitly selects the same-cluster local reviewer behavior.
- Added the exact k3s API endpoint (`192.168.8.130:6443`) to Vault egress policy after a live
  pod check proved k3s evaluates the request after Service DNAT rather than against the existing
  `10.43.0.1:443` Service rule.

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
- Implement the same-cluster development Vault integration described in
  `doc/tasks/meta-harness/runbooks/vault-integration.md`: reconcile the prepared manifests,
  recreate and unseal `vault-0`, run the operator bootstrap, and complete positive, denial,
  audit, and regression tests.

## Risks

- OIDC depends on the shared cross-cluster Authentik provider; local profile authentication is
  intentionally retained as a recovery path.
- The development PostgreSQL and node workspace claims use single-node `local-path` storage.
- Chart `0.2.2` was published twice from different trees and must not be selected again.
- A healthy workspace-broker pod does not prove Vault access; the broker constructs its Vault
  client per request, so `/credentials/resolve` and Vault audit evidence are required.
- Enabling `pushCredentialReference` during initial integration would expand the change from
  synthetic resolution testing into live Git credential use and is explicitly deferred.

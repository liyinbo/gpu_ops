# Meta Harness Development Instance Implementation Status

## Current Status

Date: 2026-08-11

The development instance is healthy on Meta Harness chart `0.3.1` and image `68904ca` with
same-cluster development Vault credential resolution live. The broker authenticates with its
projected Kubernetes identity, can resolve only the synthetic test record, and has no static
Vault token or push credential reference. Shared Authentik OIDC and local-profile recovery
remain healthy.

## Completed

- Deployed the development instance at `meta-harness-dev.home.hope-leniency.com` using a
  single-replica PostgreSQL StatefulSet and an in-cluster execution node.
- Corrected DNS to the GPU node Traefik address `192.168.8.130`.
- Updated the pinned chart through `0.3.1`; it retains the writable `/tmp` scratch volumes
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
- Reconciled chart `0.3.1` values with image `68904ca`, the dedicated broker identity,
  `authRole=meta-harness-workspace-broker-dev`, and only the synthetic reference allowlist.
  No static Vault token, push credential reference, or real Git credential is configured.
- Configured Kubernetes auth to load the rotating reviewer token and CA directly from the
  Vault pod ServiceAccount projection. Supplying a CA value while omitting the reviewer token
  made Vault fall back to the audience-scoped client JWT for TokenReview and was rejected;
  the bootstrap now explicitly selects the same-cluster local reviewer behavior.
- Added the exact k3s API endpoint (`192.168.8.130:6443`) to Vault egress policy after a live
  pod check proved k3s evaluates the request after Service DNAT rather than against the existing
  `10.43.0.1:443` Service rule.
- Added a hidden-prompt synthetic preload helper that generates a random non-production secret
  in memory, writes a typed KV v2 record through stdin with a 30-minute expiry, and removes the
  ephemeral root CLI token cache.
- Recreated and operator-unsealed the `OnDelete` Vault pod, enabled the persistent file audit
  device, and bootstrapped the `meta-harness-dev/` KV v2 mount, exact policy, Kubernetes auth
  mount, and role without committing or printing operator credentials.
- Removed the completed integration handoff prompt. The production-Vault isolation decision
  remains in `requirements.md` and the integration runbook; no production Vault material was
  accessed or copied.
- Verified the live Authentik provider blueprint has the exact development callback and client
  ID, and its client secret matches the GPU-cluster OIDC Secret without printing either value.
- Upgraded to image `68904ca`, which exposes the configured Authentik sign-in action in the SPA
  and redirects a successful authorization-code callback to `/app/`; local profiles remain the
  recovery path.

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
- `scripts/run-static-checks.sh` and `git diff --check`: pass on 2026-08-11 after the final
  policy, network, bootstrap, and preload changes.
- Flux source and all seven Kustomizations: `Ready=True` at `main@sha1:dfb01ea5` on
  2026-08-11; Meta Harness Helm revision 5 is ready on chart `0.3.1`.
- `vault-audit`: bound 1 GiB `vault-local` claim with prune disabled; `vault-0` mounts it at
  `/vault/audit` while its only StatefulSet claim template remains `data`.
- Vault: initialized, unsealed, healthy; file audit log non-empty; ephemeral root CLI token
  cache absent after both idempotent bootstrap helpers.
- Live Kubernetes login: projected audience `vault` token authenticated as
  `meta-harness/meta-harness-workspace-broker`, received the exact broker policy with a TTL no
  greater than 20 minutes, and was recorded successfully in the persistent audit log with role
  `meta-harness-workspace-broker-dev`.
- Exact-path policy: synthetic record read returned HTTP 200; sibling read and mount listing
  returned HTTP 403.
- Broker resolution: exact target returned username `vault-dev-test` and a non-empty secret
  without printing it. Wrong host, repository, scope, unknown reference, and sibling reference
  each returned HTTP 403 with no credential fields.
- Runtime broker spec: dedicated ServiceAccount, audience `vault`, CA-only Secret, exact single
  reference allowlist, image `68904ca`, and no static token or push credential environment.
- All seven Meta Harness pods: `Running`, ready, and zero restarts; application HTTPS returned
  HTTP 200; OIDC returned the exact Authentik development callback; local profile auth returned
  HTTP 200; node `cluster` reported connected with read, patch, and commit tools.
- Approved Git regression: a throwaway node workspace staged an un-applied patch proposal,
  applied it only after approval, completed approved `git.commit`, and recorded
  `candidate.committed`; no temporary-directory error occurred.
- Meta Harness source commit `68904ca`: full CI passed with 143 frontend tests and 288 Python
  tests, production SPA build, schema migration, frontend bundle validation, and Helm checks.
- Authentik browser rollout: Helm revision 6 is ready with all Meta Harness components on image
  `68904ca`; `/auth/config` reports OIDC and local recovery enabled. A fresh Playwright browser
  displayed both options and the Authentik action reached the live authentication flow with the
  exact client ID and development callback.

## Open Items

- Complete one interactive Authentik login/callback with an operator identity; automated
  validation confirmed discovery and the authorization redirect but did not submit credentials.

## Risks

- OIDC depends on the shared cross-cluster Authentik provider; local profile authentication is
  intentionally retained as a recovery path.
- The development PostgreSQL and node workspace claims use single-node `local-path` storage.
- Chart `0.2.2` was published twice from different trees and must not be selected again.
- A healthy workspace-broker pod does not prove Vault access; the broker constructs its Vault
  client per request, so `/credentials/resolve` and Vault audit evidence are required.
- Enabling `pushCredentialReference` during initial integration would expand the change from
  synthetic resolution testing into live Git credential use and is explicitly deferred.

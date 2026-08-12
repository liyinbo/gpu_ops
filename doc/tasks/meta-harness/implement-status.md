# Meta Harness Development Instance Implementation Status

## Current Status

Date: 2026-08-12

The development instance is healthy on Meta Harness chart and image `0.3.4`. Schema
`0012_agent_provider_registry` is applied and the database contains the insert-only
`claude-live` seed as revision 1 and the real default. Mock execution remains disabled. Only
the API and worker receive the exact approved endpoint allowlist, and only
the dedicated credential-ingest and worker identities receive provider Vault roles. No
provider key environment field or Secret is deployed.

Same-cluster development Vault integration and OIDC-only Authentik sign-in remain live. The
workspace broker, both provider policies, both Kubernetes auth roles, audience, public CA,
reference allowlists, and NetworkPolicies were unchanged by Phase 30. An authenticated
administrator/adult browser comparison and the real-provider key/grant/run proof remain human
steps; no OIDC session or provider key was bypassed or synthesized for deployment validation.

## Completed

- Deployed the development instance at `meta-harness-dev.home.hope-leniency.com` using a
  single-replica PostgreSQL StatefulSet and an in-cluster execution node.
- Corrected DNS to the GPU node Traefik address `192.168.8.130`.
- Updated the pinned chart through `0.3.1`; it retains the writable `/tmp` scratch volumes
  introduced in `0.2.3`.
- Added Authentik issuer, client ID, development callback, and existing-secret reference.
- Extended `bootstrap-secrets.sh` to apply `meta-harness-oidc` when
  `OIDC_CLIENT_SECRET` is supplied and to warn that OIDC-only sign-in requires an existing
  Secret when it is not.
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
- Upgraded through image `68904ca`, which exposes the configured Authentik sign-in action in the
  SPA and redirects a successful authorization-code callback to `/app/`, then image `2bc9223`,
  which rejects disabled local authentication at the API boundary.
- Published Meta Harness chart `0.3.3` and linux/amd64 image `1f95e17`; the retrieved Forgejo
  chart contains the Phase 29 `providers.*` values and dedicated provider identity templates.
- Added exact provider policy sources without changing the existing workspace-broker policy:
  ingest has only create/update and worker has only read on
  `meta-harness-dev/data/providers/claude`.
- Added a separate idempotent hidden-prompt provider bootstrap for the two Kubernetes auth
  roles, each bound to its own rendered ServiceAccount with audience `vault`.
- Added a confidential Authentik client with a SOPS-encrypted generated client secret and a
  group-gated application in `storage_server_ops`, plus a Vault role that independently requires the exact
  `Vault GPU Operators` group claim.
- Added a one-time hidden-prompt OIDC bootstrap and an exact operator policy limited to the two
  provider policy documents and two provider Kubernetes auth roles. The routine provider
  bootstrap now uses interactive OIDC and removes its short-lived token cache.
- Added Vault egress to only `192.168.8.20:443` for Authentik discovery and token exchange.
- Published Meta Harness chart `0.3.4` and its matching linux/amd64 image from source commit
  `f268aba`, then verified both artifacts from Forgejo before changing the HelmRelease.
- Reconciled chart and image `0.3.4`, renamed the unchanged secret-free provider seed to
  `providers.seedJson`, and initially allowlisted `https://api.anthropic.com`. No Vault policy,
  role, broker configuration, NetworkPolicy, Secret, or provider credential changed.

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
- OIDC-only rollout: Meta Harness source commit `2bc9223` passed 144 frontend tests, 289 Python
  tests with 23 expected skips, production SPA build, schema migration, dependency audit, and
  Helm checks. Repository static checks also passed.
- Flux source and all seven Kustomizations reached `Ready=True` at `main@sha1:7cc15da8`; Helm
  revision 7 is ready on chart `0.3.1`, and all seven pods run ready with zero restarts on image
  `2bc9223` where applicable. HTTPS returned HTTP 200 and Vault remained healthy and unsealed.
- A fresh Playwright Chromium context displayed only `Sign in with Authentik`: zero profile
  selectors, recovery labels, or local sign-in buttons. `/auth/config` reported OIDC enabled and
  local auth disabled; direct `POST /auth/local` returned HTTP 403. The Authentik action reached
  the live authentication flow with the exact client ID and development callback.
- Phase 29 Meta Harness source gate: 158 frontend tests and 330 Python tests passed with 23
  expected skips, plus production build, zero dependency audit findings, migration, and Helm
  checks. The `gpu_ops` static gate and `git diff --check` pass with the provider deployment
  configuration; a local chart `0.3.3` render proves the distinct ServiceAccounts, roles,
  audience-scoped tokens, exact allowlist, and absence of static provider tokens or credentials.
- Restricted operator desired state: repository static checks and shell syntax checks passed on
  2026-08-12. Flux reconciled all GPU-cluster Kustomizations at `main@sha1:a84e81e2`; the live
  Vault NetworkPolicy contains only the added `192.168.8.20/32` TCP/443 Authentik rule, and a
  request from `vault-0` reached the exact per-provider OIDC issuer. Storage-cluster Flux
  reconciled revision `cbfe7782`; Authentik Helm revision 5 is ready, and live model inspection
  confirmed the initial public client, single strict callback, non-superuser group, and enabled
  group binding. Vault 2.0.3 subsequently rejected OIDC configuration without a client secret;
  desired state and bootstrap were corrected to stream a SOPS-held confidential-client secret
  directly from Authentik into Vault. The intended operator was added to the group and the
  root-authorized Vault OIDC bootstrap subsequently completed.
- The first corrected bootstrap run successfully wrote the confidential OIDC client
  configuration, then Vault 2.0.3 rejected the role because the CLI encoded inline
  `bound_claims` as a string. The role write now uses a typed JSON document over stdin so the
  group claim is a map and redirect, scope, and policy fields remain arrays. The interrupted
  run removed its root CLI token cache; the typed role write subsequently completed.
- The first routine OIDC login reached Authentik and produced an authorization code, but the
  local callback failed because `kubectl port-forward` can exit permanently when contacted
  before Vault's in-pod callback listener binds. The routine bootstrap now starts and verifies
  the Vault listener first, then starts and verifies the local tunnel, retains sanitized
  forwarding diagnostics on failure, and removes its temporary log on exit.
- Cancelling a later attempt exposed that terminating the local `kubectl exec` process does not
  reliably terminate Vault's callback listener in the pod. The script now writes a unique
  per-invocation remote PID file, verifies the command identity before killing that exact
  process during cleanup, removes the PID file, and refuses to overwrite an unrelated listener.
- Restricted operator OIDC completed on 2026-08-12 through an SSH local-forward from the browser
  host. The persistent audit log records a successful `auth/oidc/oidc/callback` that issued only
  `meta-harness-operator`, followed by successful writes and reads of exactly the two provider
  policies and two provider Kubernetes roles. The CLI token cache was absent after exit.
  Both dedicated ServiceAccounts and deployments are live and ready on image `1f95e17`; Helm
  release revision 8 is ready on chart `0.3.3`.
- Phase 30 source commit `f268aba`: `scripts/ci-check.sh` passed with 173 frontend tests and
  411 Python tests (23 expected skips), production SPA build, schema/seed check, frontend
  bundle validation, dependency audit, and Helm lint/checks.
- `gpu_ops` static checks and `git diff --check` passed on 2026-08-12. Flux source and all six
  Kustomizations reconciled `main@sha1:c7cf4e2`; Helm revision 9 is ready on chart `0.3.4`,
  all eight Meta Harness pods are ready with zero restarts, HTTPS returns HTTP 200, OIDC login
  returns HTTP 307, and disabled local auth returns HTTP 403.
- Live Phase 30 data checks found schema versions `0011_credential_grants` and
  `0012_agent_provider_registry`; the sole provider row is enabled `claude-live`, revision 1,
  default, with the unchanged opaque Vault reference and Anthropic base URL. `/runtime-info`
  reports `claude-live`, no mock engine, and no provider configuration error.
- Deployment inspection found two endpoint-allowlist environments (API and worker), two
  provider-role environments (credential-ingest and worker), zero common provider-key
  environments, no provider-key-named Secret, and no provider Vault role or token projection
  on the API deployment.
- Added the operator-approved `https://api2.limtok.net` origin to the exact endpoint allowlist
  on 2026-08-12. The provider key, Vault references, identities, policies, and roles remain
  unchanged; choosing the endpoint and matching protocol remains a Brain administrator action.

## Open Items

- Store the Claude key through the Vault tool, approve its first-use grant, and prove a real
  response plus distinct ingest/worker entries in the persistent Vault audit log.
- With authenticated sessions, confirm the Brain provider section and allowed endpoint choices
  are visible to an administrator and absent for an adult profile.

## Risks

- OIDC depends on the shared cross-cluster Authentik provider and is now the only sign-in path;
  provider or OIDC Secret outages prevent new browser sessions until repaired.
- The development PostgreSQL and node workspace claims use single-node `local-path` storage.
- Chart `0.2.2` was published twice from different trees and must not be selected again.
- A healthy workspace-broker pod does not prove Vault access; the broker constructs its Vault
  client per request, so `/credentials/resolve` and Vault audit evidence are required.
- Enabling `pushCredentialReference` during initial integration would expand the change from
  synthetic resolution testing into live Git credential use and is explicitly deferred.

# Meta Harness Development Instance Test Cases

## Static Checks

### TC-MH-001 Manifest Render

Command:

```bash
kubectl kustomize apps/meta-harness >/tmp/gpu-ops-meta-harness-render.yaml
```

Expected result: all Meta Harness manifests render without errors and the HelmRelease pins
chart `0.3.1` with image `2bc9223`, OIDC enabled, local authentication disabled, and role-based Vault
configuration.

### TC-MH-002 Bootstrap Script Syntax

Command:

```bash
sh -n apps/meta-harness/bootstrap-secrets.sh
```

Expected result: the POSIX shell syntax check passes.

### TC-MH-003 Repository Static Gate

Command:

```bash
scripts/run-static-checks.sh
```

Expected result: Ansible syntax, Kubernetes rendering, shell syntax, and task-specific checks
all pass.

## Runtime Checks

### TC-MH-010 Flux Readiness

Reconcile `gpu-apps` after the Authentik provider and secrets are available.

Expected result: the HelmRelease and all Meta Harness workloads report ready with chart
`0.3.1`.

### TC-MH-020 OIDC-Only Authentication

Open a fresh browser and follow the Authentik action, then directly call the local-auth API.

Expected result: Authentik returns to the development callback and establishes a session;
the browser offers no local profiles and the local-auth API returns HTTP 403.

### TC-MH-030 Approved Git Commit

Create a throwaway workspace, apply an approved patch, stage it, and invoke `git.commit`.

Expected result: the commit completes and no component reports `No usable temporary directory
found`.

### TC-MH-040 Private HTTPS and Node Routing

Open `https://meta-harness-dev.home.hope-leniency.com/app/` and exercise a read-only node tool
against a throwaway workspace.

Expected result: HTTPS is valid, the UI loads, the node is connected, and the operation is
routed over the node channel.

## Development Vault Checks

### TC-MH-100 Role-Based Render

Render `apps/meta-harness` after the Vault integration change.

Expected result: chart `0.3.1` renders a dedicated
`meta-harness-workspace-broker` ServiceAccount, projected `vault-identity` token with audience
`vault`, Vault CA mount, `authRole=meta-harness-workspace-broker-dev`, and no static Vault token
Secret or `pushCredentialReference`.

### TC-MH-110 Kubernetes Login

Resolve the allowlisted synthetic reference and inspect the persistent Vault audit log.

Expected result: resolution succeeds and the audit log records
`auth/kubernetes/login` for role `meta-harness-workspace-broker-dev`.

Prerequisite: from `vault-0`, the Kubernetes API must be reachable through the k3s
post-Service-DNAT endpoint allowed by `apps/vault/networkpolicy.yaml`.

### TC-MH-120 Exact-Path Policy

Test the synthetic path, a sibling path, and mount listing with the broker-issued policy.

Expected result: only `meta-harness-dev/data/tests/credential-resolve` is readable; sibling
paths and mount listing are denied.

### TC-MH-130 Credential Target Enforcement

Call `/credentials/resolve` with the valid synthetic record, then change the host, repository,
scope, and reference independently.

Expected result: the exact synthetic request succeeds; every altered request fails closed and
no response or log exposes the test secret.

### TC-MH-140 Existing Workload Regression

After reconciliation, verify Flux, all Meta Harness pods, HTTPS, OIDC routing, local-auth denial,
node connectivity, and the approved `git.commit` flow.

Expected result: existing behavior remains healthy. Git push remains disabled because no push
credential reference is configured.

### TC-MH-150 Provider Identity Separation

Render chart `0.3.3` with the deployment values and inspect the live workloads and Vault roles.

Expected result: `meta-harness-credential-ingest` and `meta-harness-worker` are separate
ServiceAccounts using audience `vault`. Ingest has create/update only and worker has read only
on `meta-harness-dev/data/providers/claude`; neither can list, delete, access the synthetic
broker path, or use a static Vault token. The existing workspace-broker role is unchanged.

### TC-MH-160 Provider Ingest And Resolution

As an administrator, store the Claude API key through the Vault tool at
`vault:providers/claude`, start a `claude-live` run, approve the first-use grant to
`brain:claude-live`, and retry.

Expected result: ingest returns only the reference; the first run fails closed with the grant
approval; the approved retry receives a real provider answer. The retained Vault audit log
contains distinct Kubernetes logins for the ingest and worker roles, and no inspected surface
prints or persists the key.

### TC-MH-170 Restricted Operator OIDC

Confirm the Authentik client is confidential, has only
`http://localhost:8250/oidc/callback`, and gates the application on `Vault GPU Operators`.
Confirm its generated secret is SOPS-encrypted and the bootstrap streams it without arguments,
environment variables, output, a repository plaintext, or a GPU-cluster Kubernetes Secret.
Log in through `scripts/vault/bootstrap-meta-harness-providers.sh` as a group member.

Expected result: Vault issues a token with only `meta-harness-operator`; it can update and read
the two provider policy documents and two provider Kubernetes roles. Attempts to access KV
records, mount or auth configuration, the workspace-broker policy or role, and unrelated
policy names return permission denied. The short-lived CLI token cache is removed on exit.

### TC-MH-180 Brain-Owned Provider Registry

Render and reconcile chart `0.3.4`, then inspect migration logs, the provider registry,
`/runtime-info`, and deployment environment names without printing any secret value. In a
browser, compare the Brain tool as a Meta Harness administrator and as an adult profile.

Expected result: schema `0012_agent_provider_registry` is applied; `claude-live` is seeded once
with its existing reference and remains the real default; exactly the API and worker receive
the normalized endpoint allowlist; only ingest and worker receive provider Vault auth roles;
no provider key environment name or Secret is rendered. The administrator can edit non-secret
provider settings using only allowlisted endpoints, while an adult cannot see that section.

## Evidence — 2026-08-11

- TC-MH-001, TC-MH-002, TC-MH-003: `kubectl kustomize`, all bootstrap shell syntax checks,
  and `scripts/run-static-checks.sh` passed; the latest render pins chart `0.3.1`, image `2bc9223`,
  OIDC enabled, local auth disabled,
  role identity, exact allowlist, and no static or push credential.
- TC-MH-010: Flux source and every Kustomization were `Ready=True` at
  `main@sha1:7cc15da8`; Helm revision 7 was ready on chart `0.3.1`.
- TC-MH-020: a fresh Playwright browser rendered only `Sign in with Authentik` and reached the
  shared Authentik flow with the exact client and callback. Profile controls were absent,
  `/auth/config` reported local auth disabled, and direct local authentication returned HTTP 403.
  Interactive operator credential submission remains separately open.
- TC-MH-030: a throwaway node workspace staged a patch, applied it after approval, completed
  approved `git.commit`, and emitted `candidate.committed` without a temporary-directory error.
- TC-MH-040: the application returned HTTPS 200 and node `cluster` was connected with the
  expected read, patch, and commit tools.
- TC-MH-100: the live broker uses its dedicated ServiceAccount, projected audience `vault`
  token, CA-only Secret, exact role and reference allowlist, and no static or push token.
- TC-MH-110: a live broker login received the exact policy and TTL at most 20 minutes; the
  retained audit log recorded a successful `auth/kubernetes/login` with the exact role,
  ServiceAccount, and namespace metadata.
- TC-MH-120: the exact KV path returned HTTP 200; sibling read and mount listing returned
  HTTP 403.
- TC-MH-130: exact resolution succeeded while wrong host, repository, scope, unknown
  reference, and sibling reference each returned HTTP 403 without credential fields. No test
  secret was printed.
- TC-MH-140: all seven pods were running, ready, and at zero restarts; HTTPS, OIDC routing,
  local-auth denial, node connectivity, and the previously approved commit regression remained
  healthy. Git push remained disabled.

## Evidence — 2026-08-12

- TC-MH-150: the live cluster has separate `meta-harness-credential-ingest` and
  `meta-harness-worker` ServiceAccounts and ready deployments on image `1f95e17`; Helm revision
  8 is ready on chart `0.3.3`. The uploaded exact-path policy sources remain disjoint.
- TC-MH-170 partial: Authentik issued an RS256-signed authorization-code callback for the
  group-bound operator. Vault audit records show only `meta-harness-operator` on the successful
  callback and on all four intended provider policy/role writes and subsequent role reads. The
  token cache was absent after the script exited. Explicit negative capability probes remain to
  be captured before TC-MH-170 is closed.
- TC-MH-180 partial: Forgejo served chart and image `0.3.4`, including a linux/amd64 runnable
  image manifest and the new chart values. Flux reconciled Helm revision 9. Schema
  `0012_agent_provider_registry`, the revision-1 default `claude-live` row, runtime default,
  disabled mock engine, and null provider configuration error were verified live. Exactly API
  and worker receive the endpoint allowlist; exactly ingest and worker receive provider Vault
  roles; the API has neither provider role nor projected provider token; no common provider-key
  environment or provider-key-named Secret exists. Application CI passed with 173 frontend and
  411 Python tests (23 expected skips), including profile-specific Brain provider UI tests.
  Authenticated live browser comparison remains open because no operator session credential was
  available to this deployment run.
- TC-MH-180 endpoint extension: Helm revision 10 is ready and live API and worker environments
  contain exactly the existing Anthropic origin and operator-approved
  `https://api2.limtok.net`. All eight pods are ready with zero restarts, runtime configuration
  remains healthy, provider-role holders remain ingest and worker only, and no provider-key
  environment was exposed.

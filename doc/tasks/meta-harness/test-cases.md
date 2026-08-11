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

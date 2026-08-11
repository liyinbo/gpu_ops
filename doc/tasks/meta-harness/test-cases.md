# Meta Harness Development Instance Test Cases

## Static Checks

### TC-MH-001 Manifest Render

Command:

```bash
kubectl kustomize apps/meta-harness >/tmp/gpu-ops-meta-harness-render.yaml
```

Expected result: all Meta Harness manifests render without errors and the HelmRelease pins
chart `0.3.1` with image `a1e8cf7`, the expected OIDC settings, and the role-based Vault
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

### TC-MH-020 OIDC and Recovery Authentication

Sign in through Authentik, then verify a local profile can still sign in when OIDC is
unavailable.

Expected result: Authentik returns to the development callback and establishes a session;
local profile authentication remains usable as the recovery path.

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

After reconciliation, verify Flux, all Meta Harness pods, HTTPS, OIDC routing, local profiles,
node connectivity, and the approved `git.commit` flow.

Expected result: existing behavior remains healthy. Git push remains disabled because no push
credential reference is configured.

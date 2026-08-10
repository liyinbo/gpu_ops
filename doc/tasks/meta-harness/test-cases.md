# Meta Harness Development Instance Test Cases

## Static Checks

### TC-MH-001 Manifest Render

Command:

```bash
kubectl kustomize apps/meta-harness >/tmp/gpu-ops-meta-harness-render.yaml
```

Expected result: all Meta Harness manifests render without errors and the HelmRelease pins
chart `0.3.0` with the expected OIDC secret reference and callback.

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
`0.3.0`.

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

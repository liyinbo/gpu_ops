# meta-harness (dev instance)

The development instance of the agent control plane. The production one lives in
`storage_server_ops`; this one deliberately differs in two ways:

- **PostgreSQL is a single-replica StatefulSet on `local-path`**, not a CNPG cluster. This
  cluster has no postgres operator, and what this database holds — sessions, events,
  approvals for throwaway experiments — is recreatable.
- **Secrets are not in git.** This repository has no `.sops.yaml` and the `gpu-apps` Flux
  Kustomization has no `decryption` stanza, so there is nowhere safe to commit them.
  Create them once with `bootstrap-secrets.sh` before Flux first reconciles this app; it
  is idempotent and safe to re-run.

Everything else matches production: the execution site is an in-cluster node agent owning
workspace storage on its own volume, and the control plane routes every file, patch,
terminal and git operation over that node's channel rather than reading a tree as a path.

## Bootstrap

```sh
KUBECONFIG=./kubeconfig-gpu-cluster.yaml apps/meta-harness/bootstrap-secrets.sh
```

Then let Flux reconcile, or `flux reconcile kustomization gpu-apps --with-source`.

## Image and chart

Both are published to the in-cluster Forgejo on the storage cluster, which this cluster
resolves over the LAN ingress VIP. Build with the buildkit builder there:

```sh
cd ../meta_harness_0
VERSION=$(git rev-parse --short HEAD) BUILDER=meta-harness-k8s sh scripts/build-linux-image.sh
sh scripts/publish-forgejo-chart.sh
```

Then bump `image.tag` (and `chart.spec.version` if the chart changed) in `helmrelease.yaml`.

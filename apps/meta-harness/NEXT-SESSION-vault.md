# Point the development instance at the production Vault

Prompt for a session working in `gpu_ops`. Written from `meta_harness_0`.

## Read this part first

This is not a configuration change. Vault runs on the **storage** cluster and is currently
unreachable from this one by design, in three separate ways:

- its Service is `ClusterIP` — there is no ingress, no LoadBalancer, no external address;
- `apps/vault/networkpolicy.yaml` is `default-deny`, and every allowed ingress source is a
  `namespaceSelector`, which can only ever match a namespace in *that* cluster;
- a Vault Kubernetes auth mount is bound to one cluster's API server, so this cluster's
  ServiceAccount tokens do not validate against the existing `auth/kubernetes` mount.

So "dev uses prod's Vault" means exposing the production secret store across a cluster
boundary and punching a hole in a default-deny policy, to serve a development instance.
That is a real security decision and it belongs to whoever owns the storage cluster, not to
this repo. **Consider the alternatives before doing any of it** — they are listed at the
bottom, and one of them is "do nothing", which is currently a defensible answer: this
instance configures no `pushCredentialReference`, so it resolves no credentials at all.

If the decision is to go ahead, here is what it actually takes.

## The application side is ready

`meta_harness_0` chart **0.3.1** (commit `1b99bc6`) added `vault.authMount`, which exists
precisely for this: a Vault serving a cluster it does not run in needs that cluster's own
auth mount, and before 0.3.1 the mount name was hardcoded to `kubernetes` with no way to
configure it. Nothing else in the platform needs to change.

This instance is on chart 0.3.0 / image `a1e8cf7`. Bump to 0.3.1 as part of this work.

## What has to happen on the storage cluster

None of this is in this repo — it needs a `storage_server_ops` session, and it should be
agreed before this repo changes at all.

1. **Reach Vault from here.** Give it an address this cluster can resolve: a MetalLB
   `LoadBalancer` Service on the LAN, or a Traefik IngressRoute with **TLS passthrough**
   (not termination — Vault must keep its own certificate, and the broker pins it with
   `vault.ca`). Whichever, the certificate must carry that hostname or the broker's CA
   verification fails.
2. **Open the NetworkPolicy.** `namespaceSelector` cannot express another cluster; this
   needs an `ipBlock` for the gpu cluster's egress CIDR. Narrow it to that CIDR and port
   8200 — the whole value of the current policy is that it is default-deny.
3. **A second Kubernetes auth mount** for this cluster:
   ```sh
   vault auth enable -path=kubernetes-gpu kubernetes
   vault write auth/kubernetes-gpu/config \
     kubernetes_host=https://<gpu-apiserver>:6443 \
     kubernetes_ca_cert=@gpu-ca.crt \
     token_reviewer_jwt=@gpu-reviewer.jwt
   ```
   The reviewer JWT belongs to a ServiceAccount **in this cluster** bound to
   `system:auth-delegator`. Note the direction: Vault must call *this* cluster's API server
   to review tokens, so the storage cluster's default-deny **egress** has to allow that too.
   That is a second hole, in the opposite direction, and it is the one people forget.

   (If the gpu API server publishes a reachable OIDC discovery document, Vault's JWT auth
   method against its JWKS avoids the reverse connection and the reviewer JWT entirely.
   Worth checking first — it is strictly less plumbing.)
4. **A role and a policy for dev.** Do **not** reuse
   `meta-harness-workspace-broker`: it grants write on
   `meta-harness/data/forgejo/storage-server-ops/write`, which is the credential that
   pushes to the real repository. A development instance should not hold it.
   ```sh
   vault write auth/kubernetes-gpu/role/meta-harness-workspace-broker-dev \
     bound_service_account_names=meta-harness-workspace-broker \
     bound_service_account_namespaces=meta-harness \
     audience=vault \
     token_policies=meta-harness-workspace-broker-dev \
     token_ttl=20m token_max_ttl=1h
   ```
   with a policy scoped to a dev-only path. Both clusters name their broker ServiceAccount
   `meta-harness-workspace-broker`, so the mount is the only thing separating them —
   another reason the two roles must not share a mount *or* a policy.

## Then, in this repo

`apps/meta-harness/helmrelease.yaml` — chart `0.3.1`, and add:

```yaml
    vault:
      enabled: true
      url: https://<the-address-from-step-1>:8200
      mount: meta-harness
      authRole: meta-harness-workspace-broker-dev
      authMount: kubernetes-gpu          # NOT the default; this cluster's own mount
      referencesJson: '{"vault:<dev-reference>":"<dev-path>"}'
      ca:
        existingSecret: meta-harness-vault-ca
        key: ca.crt
        mountPath: /var/run/meta-harness/vault-ca
```

The CA secret has to be created in this cluster too — `apps/meta-harness/bootstrap-secrets.sh`
is where the other out-of-band secrets are created. Do not set `existingSecret`: with
`authRole` set no static token is mounted, and the chart no longer requires one.

## How to verify

```sh
kubectl -n meta-harness get deploy meta-harness-workspace-broker \
  -o jsonpath='{.spec.template.spec.volumes[*].name}{"\n"}'   # expect vault-identity
kubectl -n meta-harness logs deploy/meta-harness-workspace-broker | tail -20
```

A green pod proves nothing here: the broker is constructed per request, so it starts
healthy and passes its probes whether or not any of this works. The only real check is
resolving a reference — exercise a path that calls `/credentials/resolve` and confirm the
`auth/kubernetes-gpu/login` in Vault's audit log.

## Alternatives, in the order I would consider them

1. **Do nothing.** This instance resolves no credentials today. If the goal is only to keep
   dev at parity with prod's *chart*, that is already true as of 0.3.0 — and dev's value has
   been proving the Vault-less path stays intact, which pointing it at Vault would end.
2. **A separate Vault (or dev-mode Vault) on this cluster.** Same auth mount name, no
   cross-cluster exposure, no NetworkPolicy holes in either direction, and dev secrets that
   cannot be confused with production ones. More moving parts to run, far less blast radius.
3. **Cross-cluster to the production Vault**, as above — the most configuration and the
   only option that puts the production secret store on the network of another cluster.

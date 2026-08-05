# meta-harness (dev): open items for the next session

Written 2026-08-05. The dev instance is deployed and serving on
`https://meta-harness-dev.home.hope-leniency.com/app/` — DNS was pointing at the storage
cluster's VIP and now correctly resolves to 192.168.8.130.

## 1. Chart 0.2.3 is published and not yet referenced

`helmrelease.yaml` points at **0.2.2**. Bump to **0.2.3**: it adds a writable `/tmp`
(`emptyDir`) to every component, without which an approved `git.commit` fails on the
cluster with `No usable temporary directory found`. `readOnlyRootFilesystem: true` is
correct and stays; dulwich just needs scratch space.

Reproduced here on 2026-08-05: the full loop got as far as staging and applying a patch on
the node's volume, then the commit failed. Everything else worked.

**Caution about 0.2.2:** it was published twice from different trees before that was
noticed. Prefer 0.2.3, which contains both changes.

## 2. OIDC is written but unmerged

Local branch `meta-harness-oidc` here adds `auth.oidc.*` pointing at
`https://auth.home.hope-leniency.com/application/o/meta-harness/`, and extends
`bootstrap-secrets.sh` to create the `meta-harness-oidc` secret from `OIDC_CLIENT_SECRET`.

It shares the production Authentik provider — this instance's callback is registered on it
— so there is one application rather than two that drift. The provider itself is defined in
`storage_server_ops` on its own `meta-harness-oidc` branch; **that must land first**, and
merging it restarts Authentik, briefly interrupting Forgejo and Immich SSO.

Run with the matching secret:

    OIDC_CLIENT_SECRET=<from the Authentik blueprint> \
      KUBECONFIG=./kubeconfig-gpu-cluster.yaml apps/meta-harness/bootstrap-secrets.sh

Without it the script says so and sign-in falls back to local profiles rather than failing
silently.

## 3. Worth knowing about this cluster

- No SOPS here and no `decryption` on the `gpu-apps` Kustomization, which is why secrets
  are created by script rather than committed. Setting up SOPS would be strictly better.
- No postgres operator, hence the single-replica StatefulSet on `local-path`. This
  deliberately differs from production's CNPG cluster.
- Traefik runs hostPort on the node (192.168.8.130), not behind the shared MetalLB VIP —
  the same arrangement `tts` uses.

# Development Vault Implementation Status

## Current Status

Date: 2026-08-10

The single-node development Vault is deployed, initialized, unsealed, and healthy. It uses
persistent retained local storage, internal private-CA TLS, no external exposure, and
default-deny networking permitting API access only from `meta-harness`.

## Decisions

- Use a separate GPU-cluster development Vault instead of exposing the production Vault.
- Pin HashiCorp Vault chart `0.34.0` and Vault image `2.0.3`.
- Use one Shamir share with threshold one because this is a single-node development service.
- Keep initialization material outside Git and outside the repository.
- Defer Meta Harness authentication, policies, and credential ingestion until Vault itself is
  deployed and healthy.

## Validation

- Git/Flux revision `3c887ae` reconciled successfully on 2026-08-10.
- HashiCorp HelmRepository: `Ready=True`.
- Vault HelmRelease: `Ready=True`; install succeeded with chart `0.34.0`.
- `vault-internal-ca` and `vault-server-tls` Certificates: `Ready=True`.
- `vault-local` StorageClass: `Retain` and `WaitForFirstConsumer`.
- `data-vault-0`: Bound with 5 GiB capacity on `vault-local`.
- Vault Services: ClusterIP only; no Ingress is configured.
- Pre-initialization gate: `initialized=false`, `sealed=true`.
- Post-initialization health: `initialized=true`, `sealed=false`.
- Initialization material was written outside the repository with mode 0600 and its contents
  were not printed.

## Risks

- A single node has no availability during node, pod, or local-volume failure.
- Vault seals after process restart and requires the operator-held unseal key.
- Retained local storage protects against accidental PVC deletion but not node or disk loss.
- A one-share seal is suitable only for this development boundary, not production.

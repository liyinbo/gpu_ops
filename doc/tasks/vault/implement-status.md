# Development Vault Implementation Status

## Current Status

Date: 2026-08-10

Repository implementation is ready for validation. It defines a single standalone Vault pod,
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

- Live reconciliation and initialization are pending.

## Risks

- A single node has no availability during node, pod, or local-volume failure.
- Vault seals after process restart and requires the operator-held unseal key.
- Retained local storage protects against accidental PVC deletion but not node or disk loss.
- A one-share seal is suitable only for this development boundary, not production.

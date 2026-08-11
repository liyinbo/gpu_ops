# Development Vault Implementation Roadmap

## Phase 1: Platform

- [x] Define a single-node persistent Vault deployment with internal TLS.
- [x] Add retained local storage and default-deny networking.
- [x] Add guarded initialization and health-check helpers.
- [x] Reconcile the release, initialize and unseal Vault, and record live evidence.

## Phase 2: Meta Harness Integration

- [x] Define the development-only KV mount, synthetic validation record, and least-privilege
  policy in the Meta Harness integration documentation.
- [ ] Configure same-cluster Kubernetes authentication for the workspace broker.
- [ ] Upgrade Meta Harness to a chart supporting role-based Vault authentication.
- [ ] Resolve a non-production test reference end to end.

## Phase 3: Operations

- [ ] Define snapshot backup and restore requirements if development secrets become durable.
- [ ] Define unseal recovery and certificate restart procedures.

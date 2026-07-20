# TTS Implementation Roadmap

## Phase 1: Design

- [x] Select the first model target, expected model artifact source, and serving API.
- [x] Define streaming protocol, request/response format, and voice clone input handling.
- [x] Define the web UI workflows for all service functions: streaming synthesis, voice clone reference input, voice/model options, playback, status, and error handling.
- [x] Decide storage for model cache, uploaded reference audio, and generated test artifacts.
- [x] Decide the private hostname and ingress endpoint. Initial target: `tts.home.hope-leniency.com`.

## Phase 2: Runtime Packaging

- [x] Define the vLLM-Omni container image and startup command.
- [x] Define GPU, CPU, memory, shared memory, and storage requirements.
- [x] Add health, readiness, and startup probes.

## Phase 3: GitOps Manifests

- [x] Add namespace, deployment, service, config, PVC, and ingress manifests.
- [x] Add secret references without committing secret values. No plaintext runtime secrets are required for the initial public model path.
- [x] Add scheduling constraints and GPU resource requests.
- [x] Add frontend web UI deployment or static serving path.
- [x] Add Traefik Ingress and cert-manager Certificate manifests for private HTTPS exposure.

## Phase 4: Validation

- [ ] Verify pod scheduling on the GPU node.
- [ ] Verify realtime streaming synthesis.
- [ ] Verify voice clone behavior using approved non-private test inputs.
- [ ] Verify every web UI workflow against the backend API.
- [ ] Verify private HTTPS access through `tts.home.hope-leniency.com` or the final approved hostname.
- [ ] Verify GPU memory and latency under a small load test.

## Phase 5: Operations

- [x] Add deployment, validation, rollback, and troubleshooting runbooks.
- [x] Record completed evidence in `implement-status.md`.

## Phase 6: Repository Split Design

- [x] Preserve the current known-good `gpu_ops` state as a reviewable rollback baseline before moving files.
- [x] Create `tts_service` with its own requirements, roadmap, status, test cases, ownership guidance, and release policy.
- [x] Record the ownership contract: `tts_service` owns application code, web assets, images, chart, and application tests; `gpu_ops` owns Flux, environment values, GPU/storage policy, TLS, ingress, DNS contract, and live validation.
- [x] Define stable compatibility contracts for resource names, labels/selectors, service ports, probe paths, API routes, namespace, hostname, and the existing PVC.
- [x] Select the OCI registry paths, release versioning scheme, image retention policy, and chart provenance/signing policy.

Exit gate: both repositories document the same ownership and compatibility contracts, and the existing live deployment remains unchanged.

## Phase 7: Build and Publish from `tts_service`

- [x] Move the frontend assets into `tts_service` and package them in a versioned web image instead of a generated ConfigMap.
- [x] Add or wrap the model API runtime so only the supported TTS API surface is exposed and invalid inherited generation routes cannot restart the model process.
- [x] Create a reusable Helm chart for API and web Deployments, Services, probes, resources, scheduling inputs, application configuration, and optional model-cache PVC creation.
- [x] Make `existingClaim`, resource requests/limits, node selectors, tolerations, affinity, model selection, runtime arguments, and image references configurable.
- [x] Keep chart-managed Ingress and Certificate optional and disabled by default.
- [x] Add CI for image builds, Helm lint/template tests, API contract tests, streaming tests, UI tests, chart install/upgrade tests, and vulnerability scanning.
- [x] Publish immutable API/web images and the first versioned OCI chart; record image digests and chart version.

Exit gate: a clean test cluster can install the published chart, application CI passes, and all published artifacts are immutable and traceable to a source revision.

## Phase 8: Prepare `gpu_ops` Helm Deployment

- [x] Add a pinned Flux `OCIRepository` and `HelmRelease` for the published chart.
- [x] Add cluster-specific values preserving the current model, `0.40` GPU memory utilization, CPU/memory/GPU resources, probes, ports, and `Recreate` strategy.
- [x] Configure the release to reuse `tts/qwen3-tts-model-cache`; do not recreate, rename, adopt destructively, or delete the PVC.
- [x] Retain the namespace, Certificate, Traefik Ingress, hostname, exposure contract, and storage policy in `gpu_ops`.
- [x] Render the Helm release and compare its effective workload resources against the existing manifests.
- [x] Update static checks and operational scripts to validate Flux/Helm resources while retaining live service smoke tests.
- [x] Write explicit cutover and rollback steps, including how Flux pruning and Helm ownership are sequenced.

Exit gate: rendered output is compatibility-reviewed, the PVC retention path is proven, and the cutover can be rolled back without deleting cache data.

## Phase 9: Controlled Ownership Handoff

- [x] Schedule a maintenance window because the single-GPU `Recreate` workload cannot safely run legacy and Helm API pods concurrently.
- [x] Record the live Deployment, Service, PVC, Ingress, Certificate, endpoint, pod restart count, and synthesis baseline immediately before cutover.
- [x] Suspend or otherwise sequence Flux reconciliation so legacy Kustomize and Helm never manage the same objects at the same time.
- [x] Remove legacy application resources from the old Kustomize ownership boundary without pruning the retained PVC, Certificate, Ingress, or namespace.
- [x] Reconcile the pinned Helm release and verify it adopts the intended stable service contract without creating a second GPU workload.
- [x] Run scheduling, startup, web UI, streaming, voice clone, endpoint safety, HTTPS, DNS, PVC, and rollback acceptance tests.
- [x] Observe the release for an agreed soak period and compare GPU memory, first-chunk latency, total latency, errors, and restarts with the baseline.

Exit gate: all migration test cases pass, cache data remains intact, the unsafe endpoint checks pass, and the soak period shows no material regression.

## Phase 10: Cleanup and Steady-State Operations

- [x] Remove legacy Deployments, Services, ConfigMaps, frontend assets, and application-level test implementations from `gpu_ops` only after the Phase 9 exit gate passes.
- [x] Keep cluster smoke tests and deploy, validate, rollback, and troubleshooting runbooks in `gpu_ops`; link to `tts_service` for product development and chart documentation.
- [x] Configure dependency automation to propose pinned chart/image upgrades through reviewed pull requests.
- [x] Document normal upgrade, rollback, CVE response, chart compatibility, and artifact unavailability procedures.
- [x] Update status and validation evidence in both repositories and close the legacy manifest deployment path.

Exit gate: `gpu_ops` contains only cluster ownership concerns, `tts_service` is the authoritative application/chart source, and a documented rollback to the preceding chart version succeeds.

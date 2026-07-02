# TTS Implementation Roadmap

## Phase 1: Design

- Select the first model target, expected model artifact source, and serving API.
- Define streaming protocol, request/response format, and voice clone input handling.
- Define the web UI workflows for all service functions: streaming synthesis, voice clone reference input, voice/model options, playback, status, and error handling.
- Decide storage for model cache, uploaded reference audio, and generated test artifacts.
- Decide the private hostname and ingress endpoint. Initial target: `tts.home.hope-leniency.com`.

## Phase 2: Runtime Packaging

- Define the vLLM-Omni container image and startup command.
- Define GPU, CPU, memory, shared memory, and storage requirements.
- Add health, readiness, and startup probes.

## Phase 3: GitOps Manifests

- Add namespace, deployment, service, config, PVC, and optional ingress manifests.
- Add secret references without committing secret values.
- Add scheduling constraints and GPU resource requests.
- Add frontend web UI deployment or static serving path.
- Add Traefik Ingress and cert-manager Certificate manifests for private HTTPS exposure after the ingress VIP/cluster endpoint is confirmed.

## Phase 4: Validation

- Verify pod scheduling on the GPU node.
- Verify realtime streaming synthesis.
- Verify voice clone behavior using approved non-private test inputs.
- Verify every web UI workflow against the backend API.
- Verify private HTTPS access through `tts.home.hope-leniency.com` or the final approved hostname.
- Verify GPU memory and latency under a small load test.

## Phase 5: Operations

- Add deployment, validation, rollback, troubleshooting, and secret rotation runbooks.
- Record completed evidence in `implement-status.md`.

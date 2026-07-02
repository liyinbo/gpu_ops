# TTS Requirements

## Scope

Deploy realtime text-to-speech services on the GPU platform. The first target is Qwen3 TTS with vLLM-Omni, but the task namespace is `tts` so additional TTS models can be supported later.

## Functional Requirements

### REQ-TTS-001 Realtime Streaming Synthesis

The service must provide a realtime streaming speech synthesis API.

### REQ-TTS-002 Voice Clone Support

The service must support a voice clone workflow without committing voice samples, speaker embeddings, model weights, or private generated audio to Git.

### REQ-TTS-003 GPU Scheduling

The service must request GPU resources through Kubernetes and run only after NVIDIA GPU Operator exposes `nvidia.com/gpu`.

### REQ-TTS-004 Model Serving Runtime

The service must use vLLM-Omni or a documented compatible serving runtime for the selected model.

### REQ-TTS-005 GitOps Deployment

The service deployment must be represented as GitOps manifests under the repo, with secrets stored outside plaintext Git.

### REQ-TTS-006 Validation

The task must include tests for API availability, streaming behavior, GPU scheduling, voice clone behavior, and rollback safety.

### REQ-TTS-007 Web UI

The task must include a browser-based web UI for trying every supported TTS service function. The UI must support text entry, realtime streaming playback, voice clone reference input, voice/model option selection when available, request status/error display, and basic latency visibility.

### REQ-TTS-008 Private HTTPS Exposure

The web UI and API must be exposable through a private `*.home.hope-leniency.com` hostname using the house ingress pattern learned from `storage_server_ops`: Traefik Ingress, cert-manager DNS-01 certificate with `letsencrypt-prod`, and a documented DNS/exposure contract update. The initial planned hostname is `tts.home.hope-leniency.com`.

## Operational Requirements

- Do not commit model weights, private voice samples, speaker embeddings, API tokens, generated private audio, kubeconfigs, or local test artifacts.
- Keep model storage, cache paths, PVCs, and object storage locations documented.
- Document expected GPU memory, model size, latency targets, and concurrency assumptions before production use.
- Keep frontend assets and API routes in Git, but keep private voice samples and generated private audio out of Git.
- Record implementation status and validation evidence in `doc/tasks/tts/implement-status.md`.

# TTS Requirements

## Scope

Deploy realtime text-to-speech services on the GPU platform. The first target is Qwen3 TTS with vLLM-Omni, but the task namespace is `tts` so additional TTS models can be supported later.

Initial implementation target:

- Runtime image: `vllm/vllm-omni:v0.22.0`
- Model: `Qwen/Qwen3-TTS-12Hz-1.7B-Base`
- Task type: `Base`, for reference-audio voice clone
- API endpoint: OpenAI-compatible `POST /v1/audio/speech`
- Streaming mode: binary audio chunks with `stream=true`, `stream_format=audio`, and `response_format=pcm`
- Browser UI route: `/`
- API route through private ingress: `/v1`
- Initial hostname: `tts.home.hope-leniency.com`

## Functional Requirements

### REQ-TTS-001 Realtime Streaming Synthesis

The service must provide a realtime streaming speech synthesis API.

### REQ-TTS-002 Voice Clone Support

The service must support a voice clone workflow without committing voice samples, speaker embeddings, model weights, or private generated audio to Git.

Reference audio must be passed as per-request base64 data URLs or through runtime upload APIs. Private samples, generated private audio, and extracted speaker embeddings are local operational artifacts and must not be committed.

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

### REQ-TTS-009 Service Repository Boundary

Application source, frontend assets, container build definitions, application-level tests, and the reusable Helm chart must be owned by a separate `tts_service` repository. This repository remains responsible for the cluster-specific Flux release, values, GPU scheduling policy, persistent storage selection, private HTTPS exposure, and live operational validation.

### REQ-TTS-010 Immutable Release Inputs

The `tts_service` repository must publish versioned container images and a versioned OCI Helm chart. The production GitOps configuration must pin the chart version and immutable image digests or equivalently immutable image versions; it must not deploy floating `latest` tags.

### REQ-TTS-011 Migration Compatibility

The Helm-based deployment must preserve the existing `tts` namespace, public service routes, hostname, API behavior, and `qwen3-tts-model-cache` PVC data. The legacy Kustomize resources and Helm release must never concurrently manage the same Kubernetes objects.

### REQ-TTS-012 Portable and Cluster-Owned Resources

The Helm chart must own portable application resources such as Deployments, Services, probes, application configuration, and optional cache claims. Cluster-coupled Certificate, Ingress, DNS/exposure contract, storage class, existing-claim selection, and Flux resources remain owned by `gpu_ops`. Ingress and certificate creation must be disabled by default in the reusable chart.

## Operational Requirements

- Do not commit model weights, private voice samples, speaker embeddings, API tokens, generated private audio, kubeconfigs, or local test artifacts.
- Keep model storage, cache paths, PVCs, and object storage locations documented. The initial model cache PVC is `tts/qwen3-tts-model-cache`, mounted at `/models`, with Hugging Face cache under `/models/huggingface`.
- Document expected GPU memory, model size, latency targets, and concurrency assumptions before production use. Initial deployment requests one Kubernetes GPU, 24Gi memory, 4 CPU, and limits at one GPU, 48Gi memory, 12 CPU. Qwen3-TTS runs two vLLM-Omni stages on the single GPU with `--gpu-memory-utilization 0.40`; live GPU memory use is about 16GiB after warm startup. The initial latency target is first audio chunk under 5 seconds after warm model load for a short English prompt at concurrency 1; production targets must be recalibrated from live measurements.
- Keep frontend assets and API routes in Git, but keep private voice samples and generated private audio out of Git.
- Treat the current manifest deployment and its validated settings as the migration rollback baseline until the Helm release passes all acceptance tests.
- Record implementation status and validation evidence in `doc/tasks/tts/implement-status.md`.

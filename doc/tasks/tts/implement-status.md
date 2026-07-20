# TTS Implementation Status

## Current Status

Date: 2026-07-20

The initial TTS GitOps implementation is present in the repo and has been validated live. It deploys Qwen3-TTS Base on vLLM-Omni, a browser UI, Kubernetes GPU scheduling, model-cache PVC, and private HTTPS exposure for `tts.home.hope-leniency.com`.

A migration to a separate `tts_service` application repository and a pinned OCI Helm release is planned in Phases 6-10 of `implement-roadmap.md`. No deployment ownership or live cluster resources have been changed for this migration yet.

## Completed

- Created task-scoped control documents under `doc/tasks/tts/`.
- Reserved the task namespace for multiple TTS models, starting with Qwen3 TTS and vLLM-Omni.
- Added a first-class web UI requirement so all TTS service functions can be tried from a browser.
- Documented the private HTTPS exposure pattern from `storage_server_ops`: Traefik Ingress, cert-manager `letsencrypt-prod` Certificate, and DNS/exposure contract coordination for `*.home.hope-leniency.com`.
- Added `apps/tts` GitOps manifests for namespace, runtime config, model-cache PVC, vLLM-Omni API deployment, web UI deployment, services, cert-manager Certificate, and Traefik Ingress.
- Wired `apps` into `clusters/gpu-cluster`.
- Added `apps/exposure-contract.yaml` entry for `tts.home.hope-leniency.com`.
- Added browser UI assets under `apps/tts/web/` for text input, binary streaming playback, Base-task voice clone reference input, model/task/language/voice selectors, request status, errors, chunk counts, bytes, TTFB, and total latency.
- Added focused validation scripts under `scripts/tts/`.
- Updated deployment, validation, troubleshooting, and rollback runbooks.

## Verified

- Platform GPU stack is available and validated in `doc/platform/implement-status.md`.
- `scripts/run-static-checks.sh`: pass after adding TTS and private HTTPS platform manifests.
- `scripts/tts/render.sh`: pass.
- Live apply of `infrastructure/traefik`: pass after correcting Traefik to bind high container ports with hostPort 80/443.
- Live apply of `infrastructure/cert-manager`: pass; cert-manager and AliDNS webhook pods are running.
- Live apply of `infrastructure/cert-manager-issuers`: pass; `ClusterIssuer/letsencrypt-prod` reports `Ready=True`.
- Live apply of `apps/tts`: pass; namespace, ConfigMaps, services, PVC, deployments, Certificate, and Ingress were accepted.
- `KUBECONFIG_PATH=kubeconfig-gpu-cluster.yaml scripts/tts/check-web-ui.sh`: pass.
- `KUBECONFIG_PATH=kubeconfig-gpu-cluster.yaml scripts/tts/check-scheduling.sh`: pass; `qwen3-tts-api` pod scheduled on `limbo-gpu-001`, and the node reports `nvidia.com/gpu: 1`.
- `KUBECONFIG_PATH=kubeconfig-gpu-cluster.yaml scripts/tts/check-api-startup.sh`: pass after caching `vllm/vllm-omni:v0.22.0` and reducing `--gpu-memory-utilization` to `0.40` so both Qwen3-TTS stages fit on the single RTX 4090.
- `KUBECONFIG_PATH=kubeconfig-gpu-cluster.yaml scripts/tts/check-streaming.sh`: pass; generated `/tmp/gpu-ops-tts-stream.pcm` with 142080 bytes.
- `KUBECONFIG_PATH=kubeconfig-gpu-cluster.yaml scripts/tts/check-voice-clone.sh`: pass; generated `/tmp/gpu-ops-tts-clone.pcm` with 142080 bytes using a temporary non-private synthetic spoken reference.
- `KUBECONFIG_PATH=kubeconfig-gpu-cluster.yaml TRAEFIK_IP=192.168.8.130 scripts/tts/check-private-https.sh`: pass for route/resource validation.
- `curl -fsS --resolve tts.home.hope-leniency.com:443:192.168.8.130 https://tts.home.hope-leniency.com/`: pass with a valid Let's Encrypt certificate for `CN=tts.home.hope-leniency.com`.
- `KUBECONFIG_PATH=kubeconfig-gpu-cluster.yaml scripts/tts/check-rollback.sh`: pass.
- Added `scripts/tts/check-openai-endpoints.sh` to cover the vLLM-Omni/OpenAI-compatible route matrix without invoking non-TTS generation handlers that are incompatible with the Qwen3-TTS-only model.
- `scripts/tts/check-openai-endpoints.sh`: pass; validated `/health`, `/ping`, `/version`, `/v1/models`, `/v1/audio/voices`, `/v1/audio/speech`, `/v1/videos`, route registration for compatible vLLM-Omni/OpenAI route families, and absence of route families not exposed by this TTS serving mode.
- Narrowed the private Traefik Ingress from broad `/v1` forwarding to exact supported external API paths: `/v1/models`, `/v1/audio/speech`, `/v1/audio/voices`, plus `/health`. This prevents external calls to inherited non-TTS generation endpoints from reaching the TTS model process.
- Verified `POST https://tts.home.hope-leniency.com/v1/completions` now returns `404` from the web backend and does not increment the API pod restart count.
- `tts/qwen3-tts-model-cache` PVC bound with 200Gi capacity using `local-path`.
- `tts/tts-home-hope-leniency-com` Certificate: `Ready=True`; issuer is Let's Encrypt `YR1`, valid from 2026-07-02 to 2026-09-30.
- vLLM-Omni logs show warm streaming requests with `first_chunk_ms` around 84-121 ms and `total_ms` around 528-566 ms after warmup.
- GPU memory evidence: `nvidia-smi` from the API pod showed about 16043MiB used across two Qwen3-TTS stage processes.
- Local search found the expected exposure-contract consumer reference in `storage_server_ops`, but the separate `network-ops` DNS source of truth is not present under `/Users/limbo/repo`.
- Live probing showed `/v1/completions`, `/v1/chat/completions`, `/v1/responses`, `/v1/messages`, and `/v1/messages/count_tokens` are registered by the server but are not safe functional endpoints for the Qwen3-TTS-only deployment; direct requests returned 500 and restarted the API pod once. Endpoint coverage now validates these by route registration only, and the deployment recovered successfully.
- DNS verification after the network override: pass. `tts.home.hope-leniency.com` resolves to `192.168.8.130`, and `KUBECONFIG_PATH=kubeconfig-gpu-cluster.yaml TRAEFIK_IP=192.168.8.130 REQUIRE_DNS=true scripts/tts/check-private-https.sh` passes.

## Open Items

- Create and initialize the `tts_service` repository.
- Select the container/chart registry paths and artifact provenance policy.
- Decide whether the first release wraps vLLM-Omni with a TTS-only API boundary or retains ingress-only route filtering temporarily.
- Define the cutover maintenance window and post-cutover soak duration.
- Decide whether `tts.home.hope-leniency.com` should stay on GPU cluster Traefik hostPort at `192.168.8.130` or move to a future MetalLB ingress VIP.
- Decide whether to add additional Qwen3-TTS deployments for CustomVoice and VoiceDesign after Base voice clone is validated.

## Risks

- Voice clone workflows can expose sensitive biometric data if samples or embeddings are mishandled.
- Model weights and runtime images may have license or distribution constraints.
- Realtime latency depends on GPU memory, model size, concurrency, and streaming protocol behavior.
- Browser microphone upload/recording for voice clone needs explicit privacy and retention behavior before implementation.
- Private HTTPS exposure depends on Traefik, cert-manager, DNS host override, and the selected ingress VIP being ready for the GPU workload path.
- Running additional TTS model variants concurrently would require additional GPU memory or explicit scale-down/switching behavior because the initial cluster has one RTX 4090-class GPU.
- Flux pruning during the Kustomize-to-Helm ownership handoff could delete or recreate resources if the old and new ownership boundaries are not sequenced explicitly.
- Changing Deployment selectors, Service selectors, resource names, or PVC ownership during migration could cause downtime or cache loss.
- Published charts and images create a cross-repository availability and version-compatibility dependency; production references must remain immutable and retained.

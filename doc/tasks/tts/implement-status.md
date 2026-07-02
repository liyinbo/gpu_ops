# TTS Implementation Status

## Current Status

Date: 2026-07-03

The TTS task documentation structure has been created. Implementation has not started.

## Completed

- Created task-scoped control documents under `doc/tasks/tts/`.
- Reserved the task namespace for multiple TTS models, starting with Qwen3 TTS and vLLM-Omni.
- Added a first-class web UI requirement so all TTS service functions can be tried from a browser.
- Documented the private HTTPS exposure pattern from `storage_server_ops`: Traefik Ingress, cert-manager `letsencrypt-prod` Certificate, and DNS/exposure contract coordination for `*.home.hope-leniency.com`.

## Verified

- Platform GPU stack is available and validated in `doc/platform/implement-status.md`.

## Open Items

- Confirm the exact Qwen3 TTS model artifact and license constraints.
- Confirm vLLM-Omni image/source and deployment command.
- Define realtime streaming API protocol.
- Define web UI implementation approach and route layout.
- Define voice clone data handling and retention policy.
- Define model cache/storage requirements.
- Confirm whether `tts.home.hope-leniency.com` should route directly to the GPU cluster ingress VIP or through an existing storage/NAS ingress hop.
- Confirm where the exposure contract and DNS host override will be maintained for the TTS endpoint.

## Risks

- Voice clone workflows can expose sensitive biometric data if samples or embeddings are mishandled.
- Model weights and runtime images may have license or distribution constraints.
- Realtime latency depends on GPU memory, model size, concurrency, and streaming protocol behavior.
- Browser microphone upload/recording for voice clone needs explicit privacy and retention behavior before implementation.
- Private HTTPS exposure depends on Traefik, cert-manager, DNS host override, and the selected ingress VIP being ready for the GPU workload path.

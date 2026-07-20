# TTS Test Cases

## Static Checks

### TC-TTS-001 Manifest Render

Command:

```bash
scripts/tts/render.sh
```

Expected result: TTS manifests render without errors.

### TC-TTS-002 Static Gate

Command:

```bash
scripts/run-static-checks.sh
```

Expected result: repository static checks pass, including the TTS kustomize render and shell syntax checks.

## Runtime Checks

### TC-TTS-010 Pod Scheduling

Command:

```bash
KUBECONFIG_PATH=kubeconfig-gpu-cluster.yaml scripts/tts/check-scheduling.sh
```

Expected result: TTS pod schedules on a GPU-capable node and consumes `nvidia.com/gpu`.

### TC-TTS-011 API Startup

Command:

```bash
KUBECONFIG_PATH=kubeconfig-gpu-cluster.yaml scripts/tts/check-api-startup.sh
```

Expected result: the vLLM-Omni API deployment becomes available, proving the runtime image pulled and the health endpoint passed startup/readiness probes.

### TC-TTS-020 Streaming Synthesis

Command:

```bash
KUBECONFIG_PATH=kubeconfig-gpu-cluster.yaml scripts/tts/check-streaming.sh
```

Expected result: API returns streamed audio chunks for a text prompt within the documented latency target.

### TC-TTS-030 Voice Clone

Command:

```bash
KUBECONFIG_PATH=kubeconfig-gpu-cluster.yaml scripts/tts/check-voice-clone.sh
```

Expected result: API accepts an approved test reference voice input and produces speech using the requested cloned voice behavior without storing private test artifacts in Git.

### TC-TTS-040 Rollback

Command:

```bash
KUBECONFIG_PATH=kubeconfig-gpu-cluster.yaml scripts/tts/check-rollback.sh
```

Expected result: workload can be rolled back to the previous Git revision without orphaning secrets, PVCs, or GPU workloads.

### TC-TTS-050 Web UI Functional Coverage

Command:

```bash
KUBECONFIG_PATH=kubeconfig-gpu-cluster.yaml scripts/tts/check-web-ui.sh
```

Expected result: browser UI can exercise every supported TTS function, including text synthesis, realtime streaming playback, voice clone reference input, option selection, request progress, and error display.

### TC-TTS-060 Private HTTPS Exposure

Command:

```bash
KUBECONFIG_PATH=kubeconfig-gpu-cluster.yaml TRAEFIK_IP=<ingress-ip> scripts/tts/check-private-https.sh
```

Expected result: `https://tts.home.hope-leniency.com` or the final approved hostname serves the web UI over a valid cert-manager-issued certificate, routes supported API calls to the TTS backend, and blocks non-TTS generation endpoints such as `/v1/completions` before they reach the Qwen3-TTS model process.

After DNS is updated, run:

```bash
KUBECONFIG_PATH=kubeconfig-gpu-cluster.yaml TRAEFIK_IP=<ingress-ip> REQUIRE_DNS=true scripts/tts/check-private-https.sh
```

Expected result: DNS resolves the hostname to the selected ingress endpoint and the URL works without `--resolve`.

### TC-TTS-070 OpenAI-Compatible Endpoint Matrix

Command:

```bash
scripts/tts/check-openai-endpoints.sh
```

Expected result: the live API service exposes the supported vLLM-Omni/OpenAI-compatible route families for this deployment, positively validates `/health`, `/ping`, `/version`, `/v1/models`, `/v1/audio/voices`, `/v1/audio/speech`, and `/v1/videos`, validates structured error handling for an invalid speech request, and confirms non-TTS route families are either registered without invoking incompatible generation handlers or absent in the current TTS serving mode.

## Helm Migration Checks

### TC-TTS-100 Pinned Artifact Render

Render the Flux source, HelmRelease, and chart values in CI.

Expected result: the release references a fixed chart version and immutable image versions or digests, renders without errors, and does not enable chart-managed Ingress or Certificate resources.

### TC-TTS-110 Legacy Compatibility Diff

Compare the rendered Helm workload with the current Kustomize deployment before cutover.

Expected result: namespace, workload strategy, selectors, service names and ports, probe paths, model/runtime settings, resource requests, GPU request, volume mount, and externally routed API paths are unchanged or every intentional difference is reviewed and documented.

### TC-TTS-120 PVC Retention

Inspect the rendered release and live PVC before and after cutover.

Expected result: the release uses the existing `tts/qwen3-tts-model-cache` claim, the PVC UID and bound volume remain unchanged, cached model data remains readable, and rollback does not delete the claim.

### TC-TTS-130 Single Owner Cutover

Inspect Flux Kustomization and HelmRelease reconciliation history and live object ownership during cutover.

Expected result: legacy Kustomize and Helm do not simultaneously reconcile the same Deployment, Service, or ConfigMap, and no second API pod competes for the single GPU.

### TC-TTS-140 Helm Release Runtime Acceptance

Run TC-TTS-010 through TC-TTS-070 against the Helm-managed release.

Expected result: all existing scheduling, startup, synthesis, voice clone, rollback, UI, HTTPS, DNS, and endpoint-safety behavior passes without a material regression from the recorded baseline.

### TC-TTS-150 Helm Rollback

Roll back to the preceding pinned chart release using the documented GitOps procedure.

Expected result: Flux reports the preceding Helm release ready, the API and UI recover, the existing model-cache PVC remains bound, and a smoke synthesis succeeds.

### TC-TTS-160 Post-Cutover Soak

Observe the Helm-managed release for the duration specified in the cutover runbook.

Expected result: pod restarts, error rate, GPU memory, warm first-chunk latency, and total synthesis latency remain within the documented baseline or approved tolerances.

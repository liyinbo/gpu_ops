# TTS Test Cases

## Static Checks

### TC-TTS-001 Manifest Render

Command: to be defined after manifests exist.

Expected result: TTS manifests render without errors.

## Runtime Checks

### TC-TTS-010 Pod Scheduling

Expected result: TTS pod schedules on a GPU-capable node and consumes `nvidia.com/gpu`.

### TC-TTS-020 Streaming Synthesis

Expected result: API returns streamed audio chunks for a text prompt within the documented latency target.

### TC-TTS-030 Voice Clone

Expected result: API accepts an approved test reference voice input and produces speech using the requested cloned voice behavior without storing private test artifacts in Git.

### TC-TTS-040 Rollback

Expected result: workload can be rolled back to the previous Git revision without orphaning secrets, PVCs, or GPU workloads.

### TC-TTS-050 Web UI Functional Coverage

Expected result: browser UI can exercise every supported TTS function, including text synthesis, realtime streaming playback, voice clone reference input, option selection, request progress, and error display.

### TC-TTS-060 Private HTTPS Exposure

Expected result: `https://tts.home.hope-leniency.com` or the final approved hostname serves the web UI over a valid cert-manager-issued certificate and routes API calls to the TTS backend.

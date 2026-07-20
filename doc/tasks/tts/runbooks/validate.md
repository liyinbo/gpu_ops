# TTS Validate Runbook

Use only non-private test inputs. The voice clone script creates a temporary synthetic WAV under `/tmp` and deletes it on exit.

## Static

```bash
scripts/tts/render.sh
scripts/run-static-checks.sh
```

## Runtime

```bash
KUBECONFIG_PATH=kubeconfig-gpu-cluster.yaml scripts/tts/check-scheduling.sh
KUBECONFIG_PATH=kubeconfig-gpu-cluster.yaml scripts/tts/check-api-startup.sh
KUBECONFIG_PATH=kubeconfig-gpu-cluster.yaml scripts/tts/check-web-ui.sh
KUBECONFIG_PATH=kubeconfig-gpu-cluster.yaml scripts/tts/check-streaming.sh
KUBECONFIG_PATH=kubeconfig-gpu-cluster.yaml scripts/tts/check-voice-clone.sh
```

Expected checks:

- pod readiness
- GPU allocation
- streaming synthesis response with `speech.audio.delta` and `speech.audio.done`
- voice clone response using the synthetic non-private test input
- web UI loads and includes streaming controls
- basic latency observation from the browser UI and command timing

## Private Hostname Checks

After ingress is implemented:

```bash
KUBECONFIG_PATH=kubeconfig-gpu-cluster.yaml TRAEFIK_IP=<ingress-ip> scripts/tts/check-private-https.sh
curl -k -fsS --resolve tts.home.hope-leniency.com:443:<ingress-ip> https://tts.home.hope-leniency.com/health
curl -k -fsS --resolve tts.home.hope-leniency.com:443:<ingress-ip> https://tts.home.hope-leniency.com/
```

Use `--resolve tts.home.hope-leniency.com:443:<ingress-ip>` before DNS is updated.

After the DNS host override is updated, require DNS in the validation:

```bash
KUBECONFIG_PATH=kubeconfig-gpu-cluster.yaml TRAEFIK_IP=<ingress-ip> REQUIRE_DNS=true scripts/tts/check-private-https.sh
```

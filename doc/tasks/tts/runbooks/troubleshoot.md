# TTS Troubleshooting Runbook

## Flux and Helm

```bash
flux --kubeconfig kubeconfig-gpu-cluster.yaml get sources oci -n tts
flux --kubeconfig kubeconfig-gpu-cluster.yaml get helmreleases -n tts
kubectl --kubeconfig kubeconfig-gpu-cluster.yaml -n tts describe helmrelease tts-service
```

The OCI source must report the digest pinned in `apps/tts/oci-repository.yaml`. The HelmRelease uses a 30-minute timeout because model warmup can exceed Helm's five-minute default.

## Pod and GPU

```bash
kubectl --kubeconfig kubeconfig-gpu-cluster.yaml -n tts get pods -o wide
kubectl --kubeconfig kubeconfig-gpu-cluster.yaml -n tts describe pod -l app.kubernetes.io/name=qwen3-tts-api
kubectl --kubeconfig kubeconfig-gpu-cluster.yaml get nodes -o jsonpath='{range .items[*]}{.metadata.name}{" "}{.status.allocatable.nvidia\.com/gpu}{"\n"}{end}'
```

If the pod is pending, confirm the GPU Operator is ready and the node reports allocatable `nvidia.com/gpu`.

## Runtime Startup

```bash
kubectl --kubeconfig kubeconfig-gpu-cluster.yaml -n tts logs deploy/qwen3-tts-api -f
kubectl --kubeconfig kubeconfig-gpu-cluster.yaml -n tts get pvc qwen3-tts-model-cache
```

Model download failures usually show in the vLLM-Omni logs. Do not paste private tokens into manifests; use a Kubernetes Secret if a model source later requires authentication.

Image pull failures show before vLLM starts:

```bash
kubectl --kubeconfig kubeconfig-gpu-cluster.yaml -n tts describe pod -l app.kubernetes.io/name=qwen3-tts-api
```

If the event is a Docker Hub timeout or EOF, retry the pod after registry access recovers:

```bash
kubectl --kubeconfig kubeconfig-gpu-cluster.yaml -n tts delete pod -l app.kubernetes.io/name=qwen3-tts-api
```

## API

```bash
kubectl --kubeconfig kubeconfig-gpu-cluster.yaml -n tts port-forward svc/qwen3-tts-api 18091:80
curl -fsS http://127.0.0.1:18091/health
```

Run `scripts/tts/check-streaming.sh` and inspect `/tmp/gpu-ops-tts-stream.pcm` if streaming fails.

## Web UI

```bash
kubectl --kubeconfig kubeconfig-gpu-cluster.yaml -n tts port-forward svc/tts-web 18080:80
open http://127.0.0.1:18080/
```

The browser UI calls same-origin `/health`, `/v1/audio/voices`, and `/v1/audio/speech`. The web image proxies only supported TTS routes and returns 404 for other `/v1` paths. If direct web UI works but the hostname fails, focus on Ingress, TLS, or DNS.

## Private HTTPS Troubleshooting

Follow the `storage_server_ops` private ingress pattern:

- Check Traefik Ingress: `kubectl -n tts get ingress`
- Check Certificate: `kubectl -n tts get certificate`
- Check cert-manager challenge/order if the certificate is not ready.
- Verify the DNS host override points `tts.home.hope-leniency.com` to the selected ingress VIP.
- Use `curl --resolve` to separate DNS issues from Ingress/backend issues.

# TTS Rollback Runbook

Rollback must preserve secrets and model storage unless cleanup is explicitly requested.

## Preflight

```bash
KUBECONFIG_PATH=kubeconfig-gpu-cluster.yaml scripts/tts/check-rollback.sh
```

## GitOps Chart Rollback

Change `apps/tts/oci-repository.yaml` to the preceding retained chart digest and change the web image tag/digest in `apps/tts/values.yaml` to the matching release. Update the render-script chart version in the same commit, push, and reconcile Flux:

```bash
scripts/tts/render.sh
flux --kubeconfig kubeconfig-gpu-cluster.yaml reconcile kustomization gpu-apps -n flux-system --with-source
flux --kubeconfig kubeconfig-gpu-cluster.yaml reconcile helmrelease tts-service -n tts --with-source
```

Confirm rollout state:

```bash
flux --kubeconfig kubeconfig-gpu-cluster.yaml get helmreleases -n tts
kubectl --kubeconfig kubeconfig-gpu-cluster.yaml -n tts get deploy,pod,svc,ingress,pvc
KUBECONFIG_PATH=kubeconfig-gpu-cluster.yaml scripts/tts/check-streaming.sh
```

## Emergency Scale-Down

If the TTS API is consuming the only GPU and must be stopped without deleting model cache:

```bash
kubectl --kubeconfig kubeconfig-gpu-cluster.yaml -n tts scale deployment/qwen3-tts-api --replicas=0
```

Scale back to one replica after the issue is fixed:

```bash
kubectl --kubeconfig kubeconfig-gpu-cluster.yaml -n tts scale deployment/qwen3-tts-api --replicas=1
```

Do not delete `qwen3-tts-model-cache` during a rollback unless model cache cleanup is explicitly requested.

Do not use an imperative `helm rollback`; Git is the release source of truth. The validated migration rollback moved from chart `0.1.3` to `0.1.2` by changing pinned GitOps inputs, then returned to `0.1.3`.

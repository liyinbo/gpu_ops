# TTS Rollback Runbook

Rollback must preserve secrets and model storage unless cleanup is explicitly requested.

## Preflight

```bash
KUBECONFIG_PATH=kubeconfig-gpu-cluster.yaml scripts/tts/check-rollback.sh
```

## GitOps Rollback

Revert the Git commit that introduced or changed the TTS manifests, push it, and reconcile Flux:

```bash
flux --kubeconfig kubeconfig-gpu-cluster.yaml reconcile source git gpu-ops -n flux-system
flux --kubeconfig kubeconfig-gpu-cluster.yaml reconcile kustomization gpu-cluster -n flux-system --with-source
```

Confirm rollout state:

```bash
kubectl --kubeconfig kubeconfig-gpu-cluster.yaml -n tts get deploy,pod,svc,ingress,pvc
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

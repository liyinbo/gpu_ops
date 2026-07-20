#!/usr/bin/env sh
set -eu

kubectl kustomize apps/tts >/tmp/gpu-ops-tts-render.yaml
kubectl kustomize clusters/gpu-cluster >/tmp/gpu-ops-cluster-render.yaml
helm template tts-service oci://ghcr.io/liyinbo/charts/tts-service \
  --version 0.1.2 \
  --namespace tts \
  --values apps/tts/values.yaml \
  >/tmp/gpu-ops-tts-helm-render.yaml

grep -q 'kind: OCIRepository' /tmp/gpu-ops-tts-render.yaml
grep -q 'kind: HelmRelease' /tmp/gpu-ops-tts-render.yaml
grep -q 'suspend: true' /tmp/gpu-ops-tts-render.yaml
grep -q 'tts.home.hope-leniency.com' /tmp/gpu-ops-tts-render.yaml
grep -q 'kind: Deployment' /tmp/gpu-ops-tts-helm-render.yaml
grep -q 'nvidia.com/gpu' /tmp/gpu-ops-tts-helm-render.yaml
grep -q 'claimName: qwen3-tts-model-cache' /tmp/gpu-ops-tts-helm-render.yaml

if grep -q 'kind: PersistentVolumeClaim' /tmp/gpu-ops-tts-helm-render.yaml; then
  echo 'Helm render must reuse the existing model-cache PVC' >&2
  exit 1
fi

echo "tts render checks passed"

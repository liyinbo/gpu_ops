#!/usr/bin/env sh
set -eu

kubectl kustomize apps/tts >/tmp/gpu-ops-tts-render.yaml
kubectl kustomize clusters/gpu-cluster >/tmp/gpu-ops-cluster-render.yaml

grep -q 'kind: Deployment' /tmp/gpu-ops-tts-render.yaml
grep -q 'nvidia.com/gpu' /tmp/gpu-ops-tts-render.yaml
grep -q 'tts.home.hope-leniency.com' /tmp/gpu-ops-tts-render.yaml

echo "tts render checks passed"

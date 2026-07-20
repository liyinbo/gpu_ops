#!/usr/bin/env sh
set -eu

KUBECONFIG_PATH="${KUBECONFIG_PATH:-kubeconfig-gpu-cluster.yaml}"
NAMESPACE="${TTS_NAMESPACE:-tts}"

kubectl --kubeconfig "${KUBECONFIG_PATH}" -n "${NAMESPACE}" rollout history deployment/qwen3-tts-api >/tmp/gpu-ops-tts-api-rollout.txt
kubectl --kubeconfig "${KUBECONFIG_PATH}" -n "${NAMESPACE}" rollout history deployment/tts-web >/tmp/gpu-ops-tts-web-rollout.txt
kubectl --kubeconfig "${KUBECONFIG_PATH}" -n "${NAMESPACE}" get pvc qwen3-tts-model-cache >/tmp/gpu-ops-tts-pvc.txt

echo "tts rollback preflight passed"

#!/usr/bin/env sh
set -eu

KUBECONFIG_PATH="${KUBECONFIG_PATH:-kubeconfig-gpu-cluster.yaml}"
NAMESPACE="${TTS_NAMESPACE:-tts}"
DEPLOYMENT="${TTS_DEPLOYMENT:-qwen3-tts-api}"
TIMEOUT="${TTS_STARTUP_TIMEOUT:-45m}"

kubectl --kubeconfig "${KUBECONFIG_PATH}" -n "${NAMESPACE}" rollout status "deployment/${DEPLOYMENT}" --timeout="${TIMEOUT}"
kubectl --kubeconfig "${KUBECONFIG_PATH}" -n "${NAMESPACE}" get pods -l app.kubernetes.io/name="${DEPLOYMENT}" -o jsonpath='{.items[0].status.containerStatuses[0].imageID}{"\n"}' | grep -q .

echo "tts api startup check passed"

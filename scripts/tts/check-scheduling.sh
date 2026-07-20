#!/usr/bin/env sh
set -eu

KUBECONFIG_PATH="${KUBECONFIG_PATH:-kubeconfig-gpu-cluster.yaml}"
NAMESPACE="${TTS_NAMESPACE:-tts}"
DEPLOYMENT="${TTS_DEPLOYMENT:-qwen3-tts-api}"

kubectl --kubeconfig "${KUBECONFIG_PATH}" -n "${NAMESPACE}" get deployment "${DEPLOYMENT}" -o jsonpath='{.spec.template.spec.containers[0].resources.limits.nvidia\.com/gpu}{"\n"}' | grep -q '^1$'
kubectl --kubeconfig "${KUBECONFIG_PATH}" get nodes -o jsonpath='{range .items[*]}{.metadata.name}{" "}{.status.allocatable.nvidia\.com/gpu}{"\n"}{end}' | grep -E ' [1-9][0-9]*$'

pod_name="$(kubectl --kubeconfig "${KUBECONFIG_PATH}" -n "${NAMESPACE}" get pods -l app.kubernetes.io/name="${DEPLOYMENT}" -o jsonpath='{.items[0].metadata.name}')"
kubectl --kubeconfig "${KUBECONFIG_PATH}" -n "${NAMESPACE}" get pod "${pod_name}" -o jsonpath='{.spec.nodeName}{"\n"}' | grep -q .

echo "tts gpu scheduling check passed"

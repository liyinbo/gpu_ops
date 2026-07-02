#!/usr/bin/env sh
set -eu

KUBECONFIG_PATH="${KUBECONFIG_PATH:-kubeconfig-gpu-cluster.yaml}"

kubectl --kubeconfig "${KUBECONFIG_PATH}" get nodes -o wide
kubectl --kubeconfig "${KUBECONFIG_PATH}" get pods -A
kubectl --kubeconfig "${KUBECONFIG_PATH}" wait node --all --for=condition=Ready --timeout=120s

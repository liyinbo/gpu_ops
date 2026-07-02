#!/usr/bin/env sh
set -eu

KUBECONFIG_PATH="${KUBECONFIG_PATH:-kubeconfig-gpu-cluster.yaml}"
TEST_MANIFEST="${TEST_MANIFEST:-tests/nvidia-runtime-test.yaml}"
TEST_POD="${TEST_POD:-nvidia-runtime-test}"
TEST_NAMESPACE="${TEST_NAMESPACE:-default}"

kubectl --kubeconfig "${KUBECONFIG_PATH}" delete pod "${TEST_POD}" -n "${TEST_NAMESPACE}" --ignore-not-found=true
kubectl --kubeconfig "${KUBECONFIG_PATH}" apply -f "${TEST_MANIFEST}"
kubectl --kubeconfig "${KUBECONFIG_PATH}" wait pod/"${TEST_POD}" -n "${TEST_NAMESPACE}" --for=jsonpath='{.status.phase}'=Succeeded --timeout=180s
kubectl --kubeconfig "${KUBECONFIG_PATH}" logs pod/"${TEST_POD}" -n "${TEST_NAMESPACE}" | tee /tmp/gpu-ops-nvidia-runtime-test.log
grep -q "NVIDIA-SMI" /tmp/gpu-ops-nvidia-runtime-test.log

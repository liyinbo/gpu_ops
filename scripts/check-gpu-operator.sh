#!/usr/bin/env sh
set -eu

KUBECONFIG_PATH="${KUBECONFIG_PATH:-kubeconfig-gpu-cluster.yaml}"

kubectl --kubeconfig "${KUBECONFIG_PATH}" get pods -n gpu-operator
kubectl --kubeconfig "${KUBECONFIG_PATH}" get clusterpolicy
kubectl --kubeconfig "${KUBECONFIG_PATH}" get pods -n gpu-operator -o json \
  | jq -e '
      [
        .items[]
        | select(
            (.status.phase != "Running" and .status.phase != "Succeeded")
            or
            ([.status.containerStatuses[]? | select(.ready == false and (.state.terminated.reason // "") != "Completed")] | length > 0)
          )
        | .metadata.name
      ] as $bad
      | if ($bad | length) == 0 then true else error("unhealthy gpu-operator pods: \($bad | join(", "))") end
    ' >/dev/null
kubectl --kubeconfig "${KUBECONFIG_PATH}" get nodes -o json \
  | jq -e '
      [.items[] | {name: .metadata.name, allocatable: (.status.allocatable["nvidia.com/gpu"] // "0")}]
      | if any(.[]; (.allocatable | tonumber) > 0) then . else error("no nodes expose nvidia.com/gpu allocatable resources") end
    '

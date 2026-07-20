#!/usr/bin/env sh
set -eu

KUBECONFIG_PATH="${KUBECONFIG_PATH:-kubeconfig-gpu-cluster.yaml}"
NAMESPACE="${TTS_NAMESPACE:-tts}"
SERVICE="${TTS_WEB_SERVICE:-tts-web}"
PORT="${TTS_WEB_PORT:-18080}"

kubectl --kubeconfig "${KUBECONFIG_PATH}" -n "${NAMESPACE}" port-forward "svc/${SERVICE}" "${PORT}:80" >/tmp/gpu-ops-tts-web-port-forward.log 2>&1 &
pf_pid="$!"
trap 'kill "${pf_pid}" 2>/dev/null || true' EXIT
sleep 2

curl -fsS --max-time 20 "http://127.0.0.1:${PORT}/" | grep -q 'Realtime speech studio'
curl -fsS --max-time 20 "http://127.0.0.1:${PORT}/app.js" | grep -q 'stream_format'

echo "tts web ui check passed"

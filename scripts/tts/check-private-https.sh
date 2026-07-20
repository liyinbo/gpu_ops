#!/usr/bin/env sh
set -eu

KUBECONFIG_PATH="${KUBECONFIG_PATH:-kubeconfig-gpu-cluster.yaml}"
NAMESPACE="${TTS_NAMESPACE:-tts}"
HOSTNAME="${TTS_HOSTNAME:-tts.home.hope-leniency.com}"
TRAEFIK_IP="${TRAEFIK_IP:-}"
REQUIRE_DNS="${REQUIRE_DNS:-false}"

kubectl --kubeconfig "${KUBECONFIG_PATH}" -n "${NAMESPACE}" get ingress tts-ingress -o jsonpath='{.spec.ingressClassName}{"\n"}' | grep -q '^traefik$'
kubectl --kubeconfig "${KUBECONFIG_PATH}" -n "${NAMESPACE}" get certificate tts-home-hope-leniency-com -o jsonpath='{.spec.issuerRef.name}{"\n"}' | grep -q '^letsencrypt-prod$'

if test -n "${TRAEFIK_IP}"; then
  curl -fsS --max-time 20 --resolve "${HOSTNAME}:443:${TRAEFIK_IP}" "https://${HOSTNAME}/" | grep -q 'Realtime speech studio'
  curl -fsS --max-time 20 --resolve "${HOSTNAME}:443:${TRAEFIK_IP}" "https://${HOSTNAME}/v1/models" | grep -q "${TTS_MODEL:-Qwen/Qwen3-TTS-12Hz-1.7B-Base}"
  curl -fsS --max-time 20 --resolve "${HOSTNAME}:443:${TRAEFIK_IP}" "https://${HOSTNAME}/v1/audio/voices" | grep -q 'uploaded_voices'
  blocked_code="$(curl -sS --max-time 20 --resolve "${HOSTNAME}:443:${TRAEFIK_IP}" -o /tmp/gpu-ops-tts-blocked-endpoint.txt -w '%{http_code}' \
    -X POST "https://${HOSTNAME}/v1/completions" \
    -H 'Content-Type: application/json' \
    --data '{"model":"Qwen/Qwen3-TTS-12Hz-1.7B-Base","prompt":"blocked","max_tokens":1}')"
  if test "${blocked_code}" -lt 400 || test "${blocked_code}" -ge 500; then
    echo "Expected /v1/completions to be blocked at ingress with 4xx, got HTTP ${blocked_code}" >&2
    exit 1
  fi
else
  echo "TRAEFIK_IP not set; skipped live HTTPS curl"
fi

if test "${REQUIRE_DNS}" = "true"; then
  resolved_ip="$(dig +short "${HOSTNAME}" | tail -1)"
  if test "${resolved_ip}" != "${TRAEFIK_IP}"; then
    echo "DNS mismatch for ${HOSTNAME}: expected ${TRAEFIK_IP}, got ${resolved_ip:-<empty>}" >&2
    exit 1
  fi
  curl -fsS --max-time 20 "https://${HOSTNAME}/" | grep -q 'Realtime speech studio'
fi

echo "tts private https check passed"

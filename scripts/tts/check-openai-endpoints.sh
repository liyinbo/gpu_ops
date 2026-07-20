#!/usr/bin/env sh
set -eu

KUBECONFIG_PATH="${KUBECONFIG_PATH:-kubeconfig-gpu-cluster.yaml}"
NAMESPACE="${TTS_NAMESPACE:-tts}"
SERVICE="${TTS_SERVICE:-qwen3-tts-api}"
PORT="${TTS_PORT:-18093}"
BASE_URL="${TTS_BASE_URL:-}"
MODEL="${TTS_MODEL:-Qwen/Qwen3-TTS-12Hz-1.7B-Base}"
OUT="${TTS_OUT:-/tmp/gpu-ops-tts-openai-endpoints.pcm}"
REF_WAV="${TTS_REF_WAV:-/tmp/gpu-ops-tts-openai-reference.wav}"
REF_AIFF="${TTS_REF_AIFF:-/tmp/gpu-ops-tts-openai-reference.aiff}"
pf_pid=""

cleanup() {
  if test -n "${pf_pid}"; then
    kill "${pf_pid}" 2>/dev/null || true
    wait "${pf_pid}" 2>/dev/null || true
  fi
  rm -f "${REF_AIFF}" "${REF_WAV}"
}
trap cleanup EXIT

if test -z "${BASE_URL}"; then
  kubectl --kubeconfig "${KUBECONFIG_PATH}" -n "${NAMESPACE}" port-forward "svc/${SERVICE}" "${PORT}:80" >/tmp/gpu-ops-tts-openai-port-forward.log 2>&1 &
  pf_pid="$!"
  BASE_URL="http://127.0.0.1:${PORT}"
  sleep 3
fi

if command -v say >/dev/null 2>&1 && command -v afconvert >/dev/null 2>&1; then
  rm -f "${REF_AIFF}" "${REF_WAV}"
  say -o "${REF_AIFF}" "This is a synthetic reference voice for endpoint validation."
  afconvert -f WAVE -d LEI16@24000 "${REF_AIFF}" "${REF_WAV}"
else
  python3 - "${REF_WAV}" <<'PY'
import math
import struct
import sys
import wave

path = sys.argv[1]
rate = 24000
with wave.open(path, "wb") as wav:
    wav.setnchannels(1)
    wav.setsampwidth(2)
    wav.setframerate(rate)
    for index in range(int(rate * 1.2)):
        sample = int(0.2 * 32767 * math.sin(2 * math.pi * 220 * index / rate))
        wav.writeframes(struct.pack("<h", sample))
PY
fi

python3 - "${BASE_URL}" "${MODEL}" "${REF_WAV}" "${OUT}" <<'PY'
import base64
import json
import sys
import time
import urllib.error
import urllib.request

base_url, model, ref_wav, out_path = sys.argv[1:5]


def request(method, path, payload=None, timeout=60):
    body = None
    headers = {}
    if payload is not None:
        body = json.dumps(payload).encode("utf-8")
        headers["Content-Type"] = "application/json"
    req = urllib.request.Request(
        base_url + path,
        data=body,
        headers=headers,
        method=method,
    )
    start = time.monotonic()
    try:
        with urllib.request.urlopen(req, timeout=timeout) as resp:
            return resp.status, dict(resp.headers), resp.read(), time.monotonic() - start
    except urllib.error.HTTPError as exc:
        return exc.code, dict(exc.headers), exc.read(), time.monotonic() - start


def assert_status(name, status, allowed):
    if status not in allowed:
        raise SystemExit(f"{name}: expected {sorted(allowed)}, got HTTP {status}")


def assert_json(name, body):
    try:
        return json.loads(body.decode("utf-8"))
    except Exception as exc:
        raise SystemExit(f"{name}: expected JSON response: {exc}") from exc


def check_registered(path, allow):
    status, headers, body, _ = request("OPTIONS", path, timeout=15)
    if status != 405:
        raise SystemExit(f"route {path}: expected HTTP 405 to OPTIONS, got {status}")
    observed = {
        item.strip().upper()
        for item in headers.get("Allow", headers.get("allow", "")).split(",")
        if item.strip()
    }
    expected = {item.upper() for item in allow}
    if observed and not expected.issubset(observed):
        raise SystemExit(f"route {path}: expected Allow to include {sorted(expected)}, got {sorted(observed)}")


def check_absent(path):
    status, _, _, _ = request("OPTIONS", path, timeout=15)
    if status != 404:
        raise SystemExit(f"route {path}: expected absent HTTP 404, got {status}")


# Functional endpoints used by the TTS deployment.
status, _, body, _ = request("GET", "/health", timeout=20)
assert_status("GET /health", status, {200})

status, _, body, _ = request("GET", "/ping", timeout=20)
assert_status("GET /ping", status, {200})

status, _, body, _ = request("GET", "/version", timeout=20)
assert_status("GET /version", status, {200})
version = assert_json("GET /version", body)
if "version" not in version:
    raise SystemExit("GET /version: missing version key")

status, _, body, _ = request("GET", "/v1/models", timeout=20)
assert_status("GET /v1/models", status, {200})
models = assert_json("GET /v1/models", body)
ids = {item.get("id") for item in models.get("data", [])}
if model not in ids:
    raise SystemExit(f"GET /v1/models: {model!r} not in returned model ids {sorted(ids)}")

status, _, body, _ = request("GET", "/v1/audio/voices", timeout=20)
assert_status("GET /v1/audio/voices", status, {200})
voices = assert_json("GET /v1/audio/voices", body)
if "voices" not in voices or "uploaded_voices" not in voices:
    raise SystemExit("GET /v1/audio/voices: missing voices or uploaded_voices keys")

with open(ref_wav, "rb") as fh:
    ref_audio = "data:audio/wav;base64," + base64.b64encode(fh.read()).decode("ascii")

speech_payload = {
    "model": model,
    "input": "This validates the OpenAI compatible speech endpoint.",
    "task_type": "Base",
    "language": "English",
    "response_format": "pcm",
    "stream": True,
    "stream_format": "audio",
    "ref_audio": ref_audio,
    "ref_text": "This is a synthetic reference voice for endpoint validation.",
}
status, headers, body, elapsed = request("POST", "/v1/audio/speech", speech_payload, timeout=240)
assert_status("POST /v1/audio/speech", status, {200})
if len(body) <= 1024:
    raise SystemExit(f"POST /v1/audio/speech: expected audio bytes, got {len(body)} bytes")
with open(out_path, "wb") as fh:
    fh.write(body)

invalid_payload = {
    "model": model,
    "input": "This intentionally omits ref_audio.",
    "response_format": "pcm",
    "stream_format": "audio",
}
status, _, body, _ = request("POST", "/v1/audio/speech", invalid_payload, timeout=30)
assert_status("POST /v1/audio/speech invalid", status, {400})
assert_json("POST /v1/audio/speech invalid", body)

status, _, body, _ = request("GET", "/v1/videos", timeout=20)
assert_status("GET /v1/videos", status, {200})
videos = assert_json("GET /v1/videos", body)
if videos.get("object") != "list":
    raise SystemExit("GET /v1/videos: expected object=list")

# Registered vLLM-Omni/OpenAI-compatible route families for this image.
# OPTIONS validates route registration without executing handlers that are not
# compatible with the Qwen3-TTS-only model and can crash the API if invoked.
registered_routes = {
    "/health": {"GET"},
    "/ping": {"GET"},
    "/version": {"GET"},
    "/v1/models": {"GET"},
    "/tokenize": {"POST"},
    "/detokenize": {"POST"},
    "/v1/audio/speech": {"POST"},
    "/v1/audio/speech/batch": {"POST"},
    "/v1/audio/generate": {"POST"},
    "/v1/audio/voices": {"GET"},
    "/v1/audio/voices/coverage-test": {"DELETE"},
    "/v1/images/generations": {"POST"},
    "/v1/images/edits": {"POST"},
    "/v1/videos": {"POST"},
    "/v1/videos/sync": {"POST"},
    "/v1/videos/coverage-test": {"GET"},
    "/v1/videos/coverage-test/content": {"GET"},
    "/v1/omni/sleep": {"POST"},
    "/v1/omni/wakeup": {"POST"},
    "/v1/completions": {"POST"},
    "/v1/chat/completions": {"POST"},
    "/v1/responses": {"POST"},
    "/v1/responses/coverage-test": {"GET"},
    "/v1/responses/coverage-test/cancel": {"POST"},
    "/v1/messages": {"POST"},
    "/v1/messages/count_tokens": {"POST"},
}
for path, allow in registered_routes.items():
    check_registered(path, allow)

# Route families present in upstream vLLM packages but not exposed by the
# current vLLM-Omni TTS deployment mode.
absent_routes = [
    "/v1/embeddings",
    "/v1/score",
    "/v1/rerank",
    "/v1/load_lora_adapter",
    "/v1/unload_lora_adapter",
    "/v1/realtime",
    "/v1/audio/speech/stream",
    "/v1/video/chat/stream",
    "/v1/realtime/robot/openpi",
    "/v1/tokenize",
    "/v1/detokenize",
]
for path in absent_routes:
    check_absent(path)

print(
    "tts OpenAI-compatible endpoint matrix passed: "
    f"audio_bytes={len(body) if False else len(open(out_path, 'rb').read())}"
)
PY

#!/usr/bin/env sh
set -eu

KUBECONFIG_PATH="${KUBECONFIG_PATH:-kubeconfig-gpu-cluster.yaml}"
NAMESPACE="${TTS_NAMESPACE:-tts}"
SERVICE="${TTS_SERVICE:-qwen3-tts-api}"
MODEL="${TTS_MODEL:-Qwen/Qwen3-TTS-12Hz-1.7B-Base}"
PORT="${TTS_PORT:-18092}"
REF_WAV="${TTS_REF_WAV:-/tmp/gpu-ops-tts-reference.wav}"
REF_AIFF="${TTS_REF_AIFF:-/tmp/gpu-ops-tts-reference.aiff}"
OUT="${TTS_OUT:-/tmp/gpu-ops-tts-clone.pcm}"

if command -v say >/dev/null 2>&1 && command -v afconvert >/dev/null 2>&1; then
  rm -f "${REF_AIFF}" "${REF_WAV}"
  say -o "${REF_AIFF}" "This is a synthetic reference voice for validation."
  afconvert -f WAVE -d LEI16@24000 "${REF_AIFF}" "${REF_WAV}"
else
  python3 - "${REF_WAV}" <<'PY'
import math
import struct
import sys
import wave

path = sys.argv[1]
rate = 24000
duration = 1.2
with wave.open(path, "wb") as wav:
    wav.setnchannels(1)
    wav.setsampwidth(2)
    wav.setframerate(rate)
    for index in range(int(rate * duration)):
        sample = int(0.2 * 32767 * math.sin(2 * math.pi * 220 * index / rate))
        wav.writeframes(struct.pack("<h", sample))
PY
fi

ref_data="$(python3 - "${REF_WAV}" <<'PY'
import base64
import sys

with open(sys.argv[1], "rb") as fh:
    print("data:audio/wav;base64," + base64.b64encode(fh.read()).decode("ascii"))
PY
)"

payload="$(python3 - "${MODEL}" "${ref_data}" <<'PY'
import json
import sys

print(json.dumps({
    "model": sys.argv[1],
    "input": "This is a non-private synthetic voice clone validation.",
    "task_type": "Base",
    "language": "English",
    "response_format": "pcm",
    "stream": True,
    "stream_format": "audio",
    "ref_audio": sys.argv[2],
    "ref_text": "This is a synthetic reference voice for validation."
}))
PY
)"

kubectl --kubeconfig "${KUBECONFIG_PATH}" -n "${NAMESPACE}" port-forward "svc/${SERVICE}" "${PORT}:80" >/tmp/gpu-ops-tts-clone-port-forward.log 2>&1 &
pf_pid="$!"
trap 'kill "${pf_pid}" 2>/dev/null || true; wait "${pf_pid}" 2>/dev/null || true; rm -f "${REF_AIFF}" "${REF_WAV}"' EXIT
sleep 3

curl -fsS --max-time 240 \
  -H 'Content-Type: application/json' \
  -X POST "http://127.0.0.1:${PORT}/v1/audio/speech" \
  --data "${payload}" \
  -o "${OUT}"

test "$(wc -c < "${OUT}")" -gt 1024

echo "tts voice clone check passed"

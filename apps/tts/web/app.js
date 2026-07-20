const $ = (id) => document.getElementById(id);

let abortController = null;
let audioContext = null;
let scheduledAt = 0;
let chunkCount = 0;
let byteCount = 0;
let firstByteAt = 0;
let startedAt = 0;
let pcmParts = [];

function log(message) {
  const line = `[${new Date().toLocaleTimeString()}] ${message}`;
  $("log").textContent = `${line}\n${$("log").textContent}`.slice(0, 5000);
}

function setStatus(message) {
  $("requestStatus").textContent = message;
}

function formatMs(ms) {
  return `${Math.round(ms)} ms`;
}

function setMetric(id, value) {
  $(id).textContent = value;
}

async function fileToDataUrl(file) {
  if (!file) return null;
  return new Promise((resolve, reject) => {
    const reader = new FileReader();
    reader.onload = () => resolve(reader.result);
    reader.onerror = () => reject(reader.error);
    reader.readAsDataURL(file);
  });
}

function base64ToBytes(base64) {
  const binary = atob(base64);
  const out = new Uint8Array(binary.length);
  for (let i = 0; i < binary.length; i += 1) {
    out[i] = binary.charCodeAt(i);
  }
  return out;
}

function playPcmChunk(bytes, sampleRate = 24000) {
  if (!audioContext) {
    audioContext = new AudioContext({ sampleRate });
    scheduledAt = audioContext.currentTime + 0.06;
  }
  const samples = Math.floor(bytes.length / 2);
  if (samples === 0) return;
  const buffer = audioContext.createBuffer(1, samples, sampleRate);
  const channel = buffer.getChannelData(0);
  const view = new DataView(bytes.buffer, bytes.byteOffset, bytes.byteLength);
  for (let i = 0; i < samples; i += 1) {
    channel[i] = Math.max(-1, Math.min(1, view.getInt16(i * 2, true) / 32768));
  }
  const source = audioContext.createBufferSource();
  source.buffer = buffer;
  source.connect(audioContext.destination);
  const startAt = Math.max(scheduledAt, audioContext.currentTime + 0.02);
  source.start(startAt);
  scheduledAt = startAt + buffer.duration;
}

function buildWav(parts, sampleRate = 24000) {
  const dataLength = parts.reduce((total, part) => total + part.byteLength, 0);
  const out = new Uint8Array(44 + dataLength);
  const view = new DataView(out.buffer);
  const write = (offset, text) => {
    for (let i = 0; i < text.length; i += 1) out[offset + i] = text.charCodeAt(i);
  };
  write(0, "RIFF");
  view.setUint32(4, 36 + dataLength, true);
  write(8, "WAVE");
  write(12, "fmt ");
  view.setUint32(16, 16, true);
  view.setUint16(20, 1, true);
  view.setUint16(22, 1, true);
  view.setUint32(24, sampleRate, true);
  view.setUint32(28, sampleRate * 2, true);
  view.setUint16(32, 2, true);
  view.setUint16(34, 16, true);
  write(36, "data");
  view.setUint32(40, dataLength, true);
  let offset = 44;
  for (const part of parts) {
    out.set(part, offset);
    offset += part.byteLength;
  }
  return new Blob([out], { type: "audio/wav" });
}

async function refreshVoices() {
  try {
    const response = await fetch("/v1/audio/voices");
    if (!response.ok) throw new Error(`HTTP ${response.status}`);
    const data = await response.json();
    const voices = Array.isArray(data.voices) ? data.voices : [];
    $("voiceSelect").innerHTML = '<option value="">Model default</option>';
    for (const voice of voices) {
      const option = document.createElement("option");
      option.value = voice;
      option.textContent = voice;
      $("voiceSelect").appendChild(option);
    }
    log(`Loaded ${voices.length} voices`);
  } catch (error) {
    log(`Voice list unavailable: ${error.message}`);
  }
}

async function checkHealth() {
  try {
    const response = await fetch("/health");
    if (!response.ok) throw new Error(`HTTP ${response.status}`);
    $("serviceStatus").textContent = "Ready";
    $("serviceStatus").className = "status ready";
  } catch (error) {
    $("serviceStatus").textContent = "Unavailable";
    $("serviceStatus").className = "status error";
    log(`Health check failed: ${error.message}`);
  }
}

async function streamSpeech() {
  abortController = new AbortController();
  $("streamButton").disabled = true;
  $("stopButton").disabled = false;
  $("audioPlayer").removeAttribute("src");
  $("audioPlayer").load();
  pcmParts = [];
  chunkCount = 0;
  byteCount = 0;
  firstByteAt = 0;
  startedAt = performance.now();
  setMetric("ttfb", "-");
  setMetric("totalLatency", "-");
  setMetric("chunks", "0");
  setMetric("bytes", "0");
  setStatus("Preparing");

  try {
    const refAudio = await fileToDataUrl($("refAudio").files[0]);
    const payload = {
      model: $("modelSelect").value,
      input: $("textInput").value,
      task_type: $("taskType").value,
      language: $("language").value,
      instructions: $("instructions").value,
      response_format: "pcm",
      stream: true,
      stream_format: "audio"
    };
    if ($("voiceSelect").value) payload.voice = $("voiceSelect").value;
    if (refAudio) payload.ref_audio = refAudio;
    if ($("refText").value.trim()) payload.ref_text = $("refText").value.trim();

    setStatus("Streaming");
    const response = await fetch("/v1/audio/speech", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify(payload),
      signal: abortController.signal
    });
    if (!response.ok || !response.body) {
      const body = await response.text();
      throw new Error(`HTTP ${response.status}: ${body.slice(0, 300)}`);
    }

    const reader = response.body.getReader();
    while (true) {
      const { value, done } = await reader.read();
      if (done) break;
      const bytes = value instanceof Uint8Array ? value : new Uint8Array(value);
      if (!firstByteAt) {
        firstByteAt = performance.now();
        setMetric("ttfb", formatMs(firstByteAt - startedAt));
      }
      chunkCount += 1;
      byteCount += bytes.byteLength;
      pcmParts.push(bytes);
      playPcmChunk(bytes);
      setMetric("chunks", String(chunkCount));
      setMetric("bytes", String(byteCount));
    }

    const wav = buildWav(pcmParts);
    $("audioPlayer").src = URL.createObjectURL(wav);
    setStatus("Complete");
    setMetric("totalLatency", formatMs(performance.now() - startedAt));
  } catch (error) {
    if (error.name === "AbortError") {
      setStatus("Stopped");
      log("Request stopped");
    } else {
      setStatus("Error");
      log(`Error: ${error.message}`);
    }
  } finally {
    $("streamButton").disabled = false;
    $("stopButton").disabled = true;
    abortController = null;
  }
}

$("streamButton").addEventListener("click", streamSpeech);
$("stopButton").addEventListener("click", () => abortController?.abort());
$("refreshVoices").addEventListener("click", refreshVoices);

checkHealth();
refreshVoices();

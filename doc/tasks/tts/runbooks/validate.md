# TTS Validate Runbook

Validation steps will be filled in when the TTS service is implemented.

Expected checks:

- pod readiness
- GPU allocation
- streaming synthesis response
- voice clone test response
- web UI loads in a browser
- web UI can exercise all supported service functions
- private HTTPS hostname serves a valid certificate
- basic latency and error-rate observations

## Private Hostname Checks

After ingress is implemented:

```bash
curl -k -fsS https://tts.home.hope-leniency.com/health
curl -k -fsS https://tts.home.hope-leniency.com/
```

Use `--resolve tts.home.hope-leniency.com:443:<ingress-ip>` before DNS is updated.

# TTS Troubleshooting Runbook

Troubleshooting steps will be filled in when the TTS service is implemented.

Expected areas:

- model download or cache failures
- GPU scheduling failures
- vLLM-Omni startup failures
- streaming API failures
- frontend web UI failures
- private hostname, certificate, or Traefik routing failures
- voice clone input validation failures

## Private HTTPS Troubleshooting

Follow the `storage_server_ops` private ingress pattern:

- Check Traefik Ingress: `kubectl -n tts get ingress`
- Check Certificate: `kubectl -n tts get certificate`
- Check cert-manager challenge/order if the certificate is not ready.
- Verify the DNS host override points `tts.home.hope-leniency.com` to the selected ingress VIP.
- Use `curl --resolve` to separate DNS issues from Ingress/backend issues.

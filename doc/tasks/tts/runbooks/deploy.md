# TTS Deploy Runbook

Deployment steps will be filled in when the TTS manifests are implemented.

Expected inputs:

- model artifact source
- model cache or PVC path
- serving image
- API secret references
- GPU resource request
- frontend web UI image or static asset serving path
- private hostname, initially `tts.home.hope-leniency.com`
- Traefik ingress class and cert-manager issuer availability

## Private HTTPS Pattern

Use the established `storage_server_ops` pattern for `*.home.hope-leniency.com` services. Reference implementation files inspected:

- `/Users/limbo/repo/storage_server_ops/docs/private-ingress.md`
- `/Users/limbo/repo/storage_server_ops/apps/grafana-ingress/ingress.yaml`
- `/Users/limbo/repo/storage_server_ops/apps/certificates/grafana-certificate.yaml`
- `/Users/limbo/repo/storage_server_ops/apps/exposure-contract.yaml`

Required steps:

1. Create a cert-manager `Certificate` for the hostname with `issuerRef.name: letsencrypt-prod`.
2. Create a Kubernetes `Ingress` with `ingressClassName: traefik`.
3. Put the TLS secret in the same namespace as the Ingress unless a different cross-namespace mechanism is explicitly chosen.
4. Add or update the exposure contract/DNS host override so the hostname resolves to the selected ingress VIP.
5. Validate with `curl` and browser access through the final hostname.

Example shape:

```yaml
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: tts-home-hope-leniency-com
  namespace: tts
spec:
  secretName: tts-home-hope-leniency-com-tls
  issuerRef:
    name: letsencrypt-prod
    kind: ClusterIssuer
    group: cert-manager.io
  dnsNames:
    - tts.home.hope-leniency.com
---
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: tts-ingress
  namespace: tts
spec:
  ingressClassName: traefik
  tls:
    - hosts:
        - tts.home.hope-leniency.com
      secretName: tts-home-hope-leniency-com-tls
  rules:
    - host: tts.home.hope-leniency.com
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: tts-web
                port:
                  number: 80
```

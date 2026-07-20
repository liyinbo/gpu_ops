# TTS Deploy Runbook

This runbook deploys the initial Qwen3-TTS service through the repo GitOps entry point.

## Inputs

- Model artifact source: `Qwen/Qwen3-TTS-12Hz-1.7B-Base`
- Serving image: `vllm/vllm-omni:v0.22.0`
- Model cache PVC: `tts/qwen3-tts-model-cache`, mounted at `/models`
- API GPU request/limit: `nvidia.com/gpu: 1`
- Web UI: nginx serving ConfigMap assets from `apps/tts/web/`
- Private hostname: `tts.home.hope-leniency.com`
- Ingress class: `traefik`; current single-node implementation uses Traefik hostPort 80/443 on `192.168.8.130`
- Certificate issuer: cert-manager ClusterIssuer `letsencrypt-prod`
- DNS/exposure contract: `apps/exposure-contract.yaml`

## Preflight

```bash
scripts/run-static-checks.sh
KUBECONFIG_PATH=kubeconfig-gpu-cluster.yaml scripts/check-gpu-operator.sh
kubectl --kubeconfig kubeconfig-gpu-cluster.yaml get ingressclass
kubectl --kubeconfig kubeconfig-gpu-cluster.yaml get clusterissuer letsencrypt-prod
```

If the `ClusterIssuer` is missing, install or reconcile cert-manager and the DNS-01 issuer before applying the Certificate live. If certificate challenges report `alidns-secrets` missing, create `cert-manager/alidns-secrets` out of band; do not commit DNS API credentials.

## Deploy

Flux reconciles `clusters/gpu-cluster`, which now includes `../../apps`.

```bash
kubectl --kubeconfig kubeconfig-gpu-cluster.yaml apply -k clusters/gpu-cluster
kubectl --kubeconfig kubeconfig-gpu-cluster.yaml -n tts rollout status deployment/qwen3-tts-api --timeout=30m
kubectl --kubeconfig kubeconfig-gpu-cluster.yaml -n tts rollout status deployment/tts-web --timeout=5m
```

For Flux-managed reconciliation after the commit is pushed:

```bash
flux --kubeconfig kubeconfig-gpu-cluster.yaml reconcile source git gpu-ops -n flux-system
flux --kubeconfig kubeconfig-gpu-cluster.yaml reconcile kustomization gpu-cluster -n flux-system --with-source
```

## DNS

Coordinate the DNS host override in network-ops so `tts.home.hope-leniency.com` points at the selected GPU cluster Traefik endpoint. The current live route uses `192.168.8.130` until a dedicated ingress VIP is assigned.

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

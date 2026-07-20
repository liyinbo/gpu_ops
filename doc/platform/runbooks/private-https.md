# Private HTTPS Runbook

The GPU cluster exposes private HTTPS workloads with Traefik and cert-manager.

## Current Endpoint

- Traefik runs from `infrastructure/traefik`.
- The current single-node route uses hostPort 80/443 on `192.168.8.130`.
- Workload Ingress resources should use `ingressClassName: traefik`.
- Certificates should reference ClusterIssuer `letsencrypt-prod`.

## DNS-01 Secret

Create the AliDNS credential Secret out of band. Do not commit DNS API credentials in plaintext.

```bash
kubectl --kubeconfig kubeconfig-gpu-cluster.yaml -n cert-manager create secret generic alidns-secrets \
  --from-literal=access-token='<access-key-id>' \
  --from-literal=secret-key='<access-key-secret>'
```

## Validate

```bash
kubectl --kubeconfig kubeconfig-gpu-cluster.yaml -n traefik-system get pods
kubectl --kubeconfig kubeconfig-gpu-cluster.yaml get ingressclass traefik
kubectl --kubeconfig kubeconfig-gpu-cluster.yaml -n cert-manager get pods
kubectl --kubeconfig kubeconfig-gpu-cluster.yaml get clusterissuer letsencrypt-prod
```

Before DNS is updated, test a route with `--resolve`:

```bash
curl -fsS --resolve tts.home.hope-leniency.com:443:192.168.8.130 https://tts.home.hope-leniency.com/
```

After DNS is updated, verify that the hostname resolves to the selected endpoint:

```bash
dig +short tts.home.hope-leniency.com
curl -fsS https://tts.home.hope-leniency.com/
```

## Troubleshooting

If a Certificate remains pending, inspect the ACME challenge:

```bash
kubectl --kubeconfig kubeconfig-gpu-cluster.yaml -n <namespace> get certificate,certificaterequest,order,challenge
kubectl --kubeconfig kubeconfig-gpu-cluster.yaml -n <namespace> describe challenge
```

`failed to load secret "cert-manager/alidns-secrets"` means the DNS API credential Secret has not been created.

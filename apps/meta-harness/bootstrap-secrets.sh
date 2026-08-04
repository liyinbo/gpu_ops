#!/usr/bin/env sh
set -eu

# Create the dev instance's secrets directly in the cluster.
#
# They are not committed because this repository has no SOPS configuration and the
# `gpu-apps` Flux Kustomization has no `decryption` stanza — there is nowhere safe to put
# them in git. Encrypted secrets would be the better answer if SOPS is ever set up here;
# until then this is the honest one.
#
# Idempotent: re-running rotates nothing and leaves existing secrets alone. Pass
# ROTATE=1 to replace them.
#
#   KUBECONFIG=./kubeconfig-gpu-cluster.yaml apps/meta-harness/bootstrap-secrets.sh

NAMESPACE="${NAMESPACE:-meta-harness}"
FORGEJO_USER="${FORGEJO_USER:-limbo}"
FORGEJO_PAT_FILE="${FORGEJO_PAT_FILE:-../meta_harness_0/.forgejo_pat}"
ROTATE="${ROTATE:-0}"

kubectl get namespace "$NAMESPACE" >/dev/null 2>&1 || kubectl create namespace "$NAMESPACE"

if [ "$ROTATE" = "0" ] && kubectl get secret meta-harness -n "$NAMESPACE" >/dev/null 2>&1; then
  echo "secret meta-harness already exists (ROTATE=1 to replace)"
else
  PG_PASSWORD="$(head -c 24 /dev/urandom | base64 | tr -dc 'A-Za-z0-9' | head -c 32)"
  kubectl create secret generic meta-harness -n "$NAMESPACE" \
    --save-config --dry-run=client -o yaml \
    --from-literal=POSTGRES_PASSWORD="$PG_PASSWORD" \
    --from-literal=DATABASE_URL="postgresql+psycopg://meta_harness:${PG_PASSWORD}@meta-harness-pg.${NAMESPACE}.svc:5432/meta_harness" \
    --from-literal=NODE_RELAY_SECRET="$(head -c 36 /dev/urandom | base64 | tr -dc 'A-Za-z0-9' | head -c 48)" \
    --from-literal=NODE_TOKEN="mhn_$(head -c 24 /dev/urandom | od -An -tx1 | tr -d ' \n')" \
    --from-literal=BUNDLE_SIGNING_SECRET="$(head -c 36 /dev/urandom | base64 | tr -dc 'A-Za-z0-9' | head -c 48)" \
    --from-literal=BUNDLE_TOKEN_SECRET="$(head -c 36 /dev/urandom | base64 | tr -dc 'A-Za-z0-9' | head -c 48)" \
    | kubectl apply -f -
  echo "created secret meta-harness"
fi

if [ ! -f "$FORGEJO_PAT_FILE" ]; then
  echo "missing Forgejo token file: $FORGEJO_PAT_FILE" >&2
  exit 66
fi
TOKEN="$(tr -d '\n\r' < "$FORGEJO_PAT_FILE")"

# The chart and the image both come from the in-cluster Forgejo on the storage cluster,
# which this cluster reaches over the LAN ingress VIP.
kubectl create secret generic forgejo-helm -n "$NAMESPACE" \
  --save-config --dry-run=client -o yaml \
  --from-literal=username="$FORGEJO_USER" \
  --from-literal=password="$TOKEN" | kubectl apply -f -

kubectl create secret docker-registry forgejo-registry -n "$NAMESPACE" \
  --save-config --dry-run=client -o yaml \
  --docker-server=forgejo.home.hope-leniency.com \
  --docker-username="$FORGEJO_USER" \
  --docker-password="$TOKEN" | kubectl apply -f -

echo "forgejo credentials in place"

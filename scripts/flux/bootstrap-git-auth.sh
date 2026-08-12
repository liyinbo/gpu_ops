#!/bin/sh
set -eu

# Bootstrap the out-of-band HTTPS credential Flux needs to read the private gpu_ops
# repository. The token is streamed to kubectl and never placed in an argument, environment
# variable, repository file, or command output.

KUBECONFIG_PATH=${KUBECONFIG_PATH:-./kubeconfig-gpu-cluster.yaml}
NAMESPACE=${NAMESPACE:-flux-system}
SECRET_NAME=${SECRET_NAME:-gpu-ops-forgejo}
FORGEJO_USERNAME=${FORGEJO_USERNAME:-limbo}
FORGEJO_REPOSITORY_API=${FORGEJO_REPOSITORY_API:-https://forgejo.home.hope-leniency.com/api/v1/repos/limbo/gpu_ops}

token=
cleanup() {
  token=
  stty echo 2>/dev/null || true
}
trap cleanup EXIT HUP INT TERM

if [ -n "${FORGEJO_PAT_FILE:-}" ]; then
  if [ ! -s "$FORGEJO_PAT_FILE" ]; then
    echo "FORGEJO_PAT_FILE does not name a non-empty file" >&2
    exit 1
  fi
  token=$(tr -d '\r\n' < "$FORGEJO_PAT_FILE")
else
  if [ ! -t 0 ]; then
    echo "run from a TTY or set FORGEJO_PAT_FILE to a protected local file" >&2
    exit 1
  fi
  printf 'Forgejo repository read token: ' >&2
  stty -echo
  IFS= read -r token
  stty echo
  printf '\n' >&2
fi

if [ -z "$token" ]; then
  echo "Forgejo token is empty" >&2
  exit 1
fi

repo_check=$(
  {
    printf 'header = "Authorization: token %s"\n' "$token"
  } | curl --connect-timeout 5 --max-time 20 --fail --silent --show-error \
    --config - "$FORGEJO_REPOSITORY_API"
)
printf '%s' "$repo_check" | jq -e \
  '.full_name == "limbo/gpu_ops" and .private == true and .permissions.pull == true' \
  >/dev/null
repo_check=

# jq reads the token from stdin and emits the Secret manifest only to kubectl.
printf '%s' "$token" | jq -Rs \
  --arg namespace "$NAMESPACE" \
  --arg name "$SECRET_NAME" \
  --arg username "$FORGEJO_USERNAME" \
  'if length == 0 then error("empty credential") else
    {apiVersion:"v1",kind:"Secret",metadata:{name:$name,namespace:$namespace},type:"Opaque",
     stringData:{username:$username,password:.}} end' \
  | kubectl --kubeconfig "$KUBECONFIG_PATH" apply -f - >/dev/null

token=
echo "Flux Forgejo read credential is configured in $NAMESPACE/$SECRET_NAME"

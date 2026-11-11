#!/bin/bash
# Module 10 fixture helpers. Source from setup.sh/validate.sh:  . ../_fixtures/lib.sh
# (solution.sh runs in an empty directory and cannot source this file.)
# All functions use $NS (default k8smissions) and the repo files next to this script.
FIX="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
NS=${NS:-k8smissions}

# lab_ns [namespace]: webhooks only match namespaces with k8smissions/lab=true, so a broken webhook is contained.
lab_ns() { kubectl label namespace "${1:-$NS}" k8smissions/lab=true --overwrite >/dev/null; }

# install_kapi: ConfigMap kapi-lib (kapi.py) for controller pods; mount at /kapi with PYTHONPATH=/kapi.
install_kapi() { kubectl -n "$NS" create configmap kapi-lib --from-file=kapi.py="$FIX/kapi.py" --dry-run=client -o yaml | kubectl apply -f - >/dev/null; }

# install_webhook_server: ConfigMap webhook-server (server.py); mount at /app, run `python -u /app/server.py`.
install_webhook_server() { kubectl -n "$NS" create configmap webhook-server --from-file=server.py="$FIX/server.py" --dry-run=client -o yaml | kubectl apply -f - >/dev/null; }

# install_handler <cm-name> <file> : ConfigMap <cm-name> with key handler.py from a file (mount at /handler).
install_handler() { kubectl -n "$NS" create configmap "$1" --from-file=handler.py="$2" --dry-run=client -o yaml | kubectl apply -f - >/dev/null; }

# tls_secret <secret-name> <good|expired|nosan|good-labeler> [namespace]: kubernetes.io/tls Secret from fixtures.
tls_secret() { kubectl -n "${3:-$NS}" create secret tls "$1" --cert="$FIX/certs/$2/tls.crt" --key="$FIX/certs/$2/tls.key" --dry-run=client -o yaml | kubectl apply -f - >/dev/null; }

# ca_secret <secret-name> <ca-a|ca-b> [namespace]: Opaque Secret with key ca.crt (for players to read a CA from).
ca_secret() { kubectl -n "${3:-$NS}" create secret generic "$1" --from-file=ca.crt="$FIX/certs/$2/ca.crt" --dry-run=client -o yaml | kubectl apply -f - >/dev/null; }

# cabundle <ca-a|ca-b>: base64 (single line) of the CA, for webhook/CRD caBundle fields.
cabundle() { base64 < "$FIX/certs/$1/ca.crt" | tr -d '\n'; }

# label_managed <kind/name>...: label cluster-scoped objects made imperatively so cleanup deletes them.
label_managed() { kubectl label "$@" k8smissions/managed=true --overwrite >/dev/null; }

# wait_crd <crd-name>: wait until the CRD is Established.
wait_crd() { kubectl wait --for=condition=Established "crd/$1" --timeout=60s >/dev/null; }

# wait_rollout <deploy>: wait for a Deployment of the level to be available.
wait_rollout() { kubectl -n "$NS" rollout status "deploy/$1" --timeout=120s >/dev/null; }

# apply_managed: apply manifests from stdin and label them k8smissions/managed=true (like the engine does for
# broken.yaml). Use it in setup.sh for CRDs and other cluster-scoped objects that must exist before CRs.
apply_managed() {
  local f; f=$(mktemp)
  cat > "$f"
  kubectl apply -f "$f" >/dev/null && kubectl label -f "$f" k8smissions/managed=true --overwrite >/dev/null
  local rc=$?; rm -f "$f"; return $rc
}

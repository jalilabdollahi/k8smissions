#!/bin/bash
# The webhook server and the stale TLS material are prepared before the webhook configuration
# (in broken.yaml) starts intercepting ConfigMap creation in this namespace.
NS=${NS:-k8smissions}
M10=../../module-10-operators/_fixtures
kubectl label namespace "$NS" k8smissions/lab=true --overwrite >/dev/null
kubectl -n "$NS" create configmap webhook-server --from-file=server.py="$M10/server.py" >/dev/null || exit 1
kubectl -n "$NS" apply -f - >/dev/null <<YAML
apiVersion: v1
kind: Secret
metadata:
  name: config-guard-tls
type: kubernetes.io/tls
data:
  tls.crt: $(base64 < "$M10/certs/good/tls.crt" | tr -d '\n')
  tls.key: $(base64 < "$M10/certs/good/tls.key" | tr -d '\n')
  ca.crt: $(base64 < "$M10/certs/ca-a/ca.crt" | tr -d '\n')
YAML

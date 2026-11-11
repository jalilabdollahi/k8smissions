#!/bin/bash
# Level 14: the consumer must authenticate with the current token, and must keep doing so after the
# validator rotates the Secret again (a pod restart alone cannot pass the second part).
. ../_fixtures/lib.sh

if ! kubectl get secret api-token -n "$NS" >/dev/null 2>&1; then
  bad "Secret api-token does not exist"
  exit 1
fi
for d in api-gateway api-consumer; do
  if ! kubectl get deployment "$d" -n "$NS" >/dev/null 2>&1; then
    bad "Deployment $d does not exist"
    exit 1
  fi
done
POD=$(kubectl get pods -n "$NS" -l app=api-consumer --field-selector=status.phase=Running \
  -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)
if [ -z "$POD" ] || \
   [ "$(kubectl get pod "$POD" -n "$NS" -o jsonpath='{.status.containerStatuses[0].ready}')" != "true" ]; then
  bad "api-consumer has no Ready pod"
  exit 1
fi
ensure_probe || { bad "could not start the test client pod"; exit 1; }

want() { kubectl get secret api-token -n "$NS" -o jsonpath='{.data.token}' | base64 -d; }
have() { kubectl exec -n "$NS" "$POD" -- cat /etc/api/token 2>/dev/null; }

# give the consumer a moment to make a request with whatever it has
sleep 3
S=$(pcurl http://api-consumer/ | tr -d '\r\n')
if [ "$S" != "auth=ok" ]; then
  bad "api-consumer reports '${S:-no answer}'; the gateway does not accept its token"
  exit 1
fi
if [ "$(have)" != "$(want)" ]; then
  bad "the token file in the pod differs from Secret api-token"
  exit 1
fi
ok "api-consumer authenticates with the current token"

NEW="tok-rot-$(date +%s)"
kubectl patch secret api-token -n "$NS" --type=merge -p "{\"stringData\":{\"token\":\"$NEW\"}}" >/dev/null 2>&1
ok "validator rotated the token; waiting for the pod to pick it up"
# the kubelet refreshes volumes on its own timer (up to ~90s); touching the pod makes it resync now
kubectl annotate pod "$POD" -n "$NS" k8smissions/rotation-check="$NEW" --overwrite >/dev/null 2>&1
sleep 5
END=$((SECONDS + 45))
while [ $SECONDS -lt $END ]; do
  S=$(pcurl http://api-consumer/ | tr -d '\r\n')
  if [ "$S" = "auth=ok" ] && [ "$(have)" = "$NEW" ]; then
    ok "the rotated token reached the pod without a restart of the workload"
    exit 0
  fi
  sleep 3
done
bad "50s after the rotation the pod still has '$(have | cut -c1-14)...' and reports '${S:-no answer}'"
exit 1

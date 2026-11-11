#!/bin/bash
# Level 3: 3 Ready replicas, one RWO claim, same content everywhere.
. ../_fixtures/lib.sh
WANT="catalogue-2024-11 release 42"

if ! kubectl get deployment web-servers -n "$NS" >/dev/null 2>&1; then
  bad "Deployment web-servers does not exist"
  exit 1
fi
SPEC=$(kubectl get deployment web-servers -n "$NS" -o jsonpath='{.spec.replicas}')
READY=$(kubectl get deployment web-servers -n "$NS" -o jsonpath='{.status.readyReplicas}')
if [ "${SPEC:-0}" -lt 3 ]; then
  bad "web-servers is set to ${SPEC:-0} replicas; the site needs 3"
  exit 1
fi
if [ "${READY:-0}" -lt 3 ]; then
  bad "only ${READY:-0} of $SPEC web-servers replicas are Ready"
  exit 1
fi
ok "$READY of $SPEC replicas are Ready"

PVCS=$(kubectl get pvc -n "$NS" -o name | wc -l | tr -d ' ')
MODES=$(kubectl get pvc site-content -n "$NS" -o jsonpath='{.spec.accessModes[*]}' 2>/dev/null)
if [ "$PVCS" != "1" ] || [ "$MODES" != "ReadWriteOnce" ]; then
  bad "expected exactly one PVC site-content with ReadWriteOnce (found $PVCS PVCs, modes: ${MODES:-none})"
  exit 1
fi
ok "one ReadWriteOnce PVC site-content is shared"

for pod in $(kubectl get pods -n "$NS" -l app=web-servers -o jsonpath='{.items[*].metadata.name}'); do
  if [ "$(kubectl get pod "$pod" -n "$NS" -o jsonpath='{.status.phase}')" != "Running" ]; then
    bad "pod $pod is not Running"
    exit 1
  fi
  got=$(kubectl exec -n "$NS" "$pod" -- wget -qO- http://localhost/content 2>/dev/null)
  if [ "$got" != "$WANT" ]; then
    bad "pod $pod does not serve the catalogue content"
    exit 1
  fi
done
ok "every pod serves the catalogue content"

ensure_probe || { bad "could not start the test client pod"; exit 1; }
BAD=0
for i in $(seq 1 30); do
  [ "$(pcurl http://web-servers/content)" = "$WANT" ] || BAD=$((BAD + 1))
done
if [ "$BAD" -ne 0 ]; then
  bad "$BAD of 30 requests through Service web-servers failed"
  exit 1
fi
ok "30 of 30 requests through Service web-servers returned the content"
exit 0
exit 1

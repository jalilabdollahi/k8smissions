#!/bin/bash
NS=${NS:-k8smissions}
k() { kubectl -n "$NS" "$@"; }
Q=queues.queue.acme.io
SA=system:serviceaccount:$NS:queue-operator

# --- the guard and the CRD must still be there, and strict ---
if ! kubectl get validatingwebhookconfiguration queue-guard >/dev/null 2>&1; then
  echo "❌ the queue-guard webhook configuration is gone"
  exit 1
fi
pol=$(kubectl get validatingwebhookconfiguration queue-guard -o jsonpath='{.webhooks[*].failurePolicy}')
if [ -z "$pol" ] || [ "$(echo "$pol" | tr ' ' '\n' | grep -vc '^Fail$')" != 0 ]; then
  echo "❌ queue-guard no longer fails closed (failurePolicy: ${pol:-unset})"
  exit 1
fi
if ! kubectl get crd $Q >/dev/null 2>&1; then
  echo "❌ the Queue CRD is gone"
  exit 1
fi

probe() {  # probe <retentionDays> <partitions>: server-side dry-run create, prints the object's deadLetter.enabled or the error
  k create --dry-run=server --validate=false -o jsonpath='{.spec.deadLetter.enabled}' -f - 2>&1 <<Y
apiVersion: queue.acme.io/v1
kind: Queue
metadata: {name: probe-admission}
spec: {partitions: $2, retentionDays: $1, deadLetter: {enabled: true, maxRetries: 3}}
Y
}

# --- 1. admission works ---
out=$(probe 7 4)
if echo "$out" | grep -qi 'x509\|failed calling webhook\|internal error'; then
  echo "❌ creating a Queue fails at admission: $(echo "$out" | head -c 300)"
  exit 1
fi
echo "✅ the queue-guard webhook can be called"

if [ "$out" != "true" ]; then
  echo "❌ a Queue created with spec.deadLetter comes back without it (the CRD schema drops the field): '$(echo "$out" | head -c 160)'"
  exit 1
fi
echo "✅ spec.deadLetter survives the CRD schema"

hook=$(probe 90 4)
if ! echo "$hook" | grep -q 'queue-guard: retentionDays'; then
  echo "❌ a Queue with retentionDays 90 is not rejected by queue-guard: $(echo "$hook" | head -c 200)"
  exit 1
fi
sch=$(probe 7 0)
if echo "$sch" | grep -q '^true$' || ! echo "$sch" | grep -qi 'partitions'; then
  echo "❌ a Queue with partitions 0 is not rejected by the CRD schema: $(echo "$sch" | head -c 200)"
  exit 1
fi
echo "✅ the webhook and the schema still reject invalid Queues"

# --- 2. the operator ---
reps=$(k get deploy queue-operator -o jsonpath='{.spec.replicas}' 2>/dev/null)
ready=$(k get deploy queue-operator -o jsonpath='{.status.readyReplicas}' 2>/dev/null)
if [ "${reps:-0}" -lt 2 ] || [ "${ready:-0}" -lt 2 ]; then
  echo "❌ queue-operator must run 2 ready replicas (spec ${reps:-0}, ready ${ready:-0})"
  exit 1
fi
if [ "$(kubectl auth can-i create leases.coordination.k8s.io -n "$NS" --as="$SA")" != yes ]; then
  echo "❌ the operator's ServiceAccount cannot create leases"
  exit 1
fi
if [ "$(kubectl auth can-i get secrets -n "$NS" --as="$SA")" != no ] || [ "$(kubectl auth can-i delete nodes --as="$SA")" != no ]; then
  echo "❌ the operator has far more permissions than it needs (it can read secrets or delete nodes)"
  exit 1
fi
leases() { k get lease -o jsonpath='{range .items[*]}{.metadata.name}{"|"}{.spec.holderIdentity}{"|"}{.spec.renewTime}{"\n"}{end}' 2>/dev/null | sort; }
l1=$(leases); sleep 5; l2=$(leases)
live=$(comm -13 <(echo "$l1") <(echo "$l2"))
n=$(echo "$live" | grep -c .)
if [ "$n" != 1 ]; then
  echo "❌ $n leases are being renewed (expected exactly one leader)"
  exit 1
fi
holder=$(echo "$live" | cut -d'|' -f2)
if ! k get pod "$holder" >/dev/null 2>&1; then
  echo "❌ the lease holder '$holder' is not a pod"
  exit 1
fi
echo "✅ one operator replica leads: $holder"

# --- 3. the user-facing outcome ---
dl=$(k get $Q orders -o jsonpath='{.spec.deadLetter.enabled}' 2>/dev/null)
if [ "$dl" != "true" ]; then
  echo "❌ Queue orders is missing or has no deadLetter setting (deadLetter.enabled: '${dl}')"
  exit 1
fi
ok=0
for i in $(seq 1 15); do
  gen=$(k get $Q orders -o jsonpath='{.metadata.generation}')
  obs=$(k get $Q orders -o jsonpath='{.status.observedGeneration}')
  ph=$(k get $Q orders -o jsonpath='{.status.phase}')
  lw=$(k get $Q orders -o jsonpath='{.status.lastWriter}')
  if [ "$ph" = Ready ] && [ "$gen" = "$obs" ] && [ "$lw" = "$holder" ] \
     && k get cm queue-orders >/dev/null 2>&1 && k get cm queue-orders-dlq >/dev/null 2>&1; then ok=1; break; fi
  sleep 1
done
if [ "$ok" != 1 ]; then
  echo "❌ Queue orders is not fully reconciled by the leader (phase '$ph', generation $gen, observed '$obs', writer '$lw', ConfigMaps queue-orders and queue-orders-dlq needed)"
  exit 1
fi
echo "✅ Queue orders is Ready with its ConfigMaps queue-orders and queue-orders-dlq"

k delete $Q probe-dlq --ignore-not-found >/dev/null 2>&1
k delete cm queue-probe-dlq queue-probe-dlq-dlq --ignore-not-found >/dev/null 2>&1
if ! k apply --validate=false -f - >/dev/null 2>&1 <<'Y'
apiVersion: queue.acme.io/v1
kind: Queue
metadata: {name: probe-dlq}
spec: {partitions: 2, retentionDays: 3, deadLetter: {enabled: true, maxRetries: 2}}
Y
then
  echo "❌ creating a new Queue with a dead-letter setting failed"
  exit 1
fi
ok=0
for i in $(seq 1 15); do
  if k get cm queue-probe-dlq >/dev/null 2>&1 && k get cm queue-probe-dlq-dlq >/dev/null 2>&1 \
     && [ "$(k get $Q probe-dlq -o jsonpath='{.status.phase}' 2>/dev/null)" = Ready ]; then ok=1; break; fi
  sleep 1
done
k delete $Q probe-dlq --ignore-not-found >/dev/null 2>&1
k delete cm queue-probe-dlq queue-probe-dlq-dlq --ignore-not-found >/dev/null 2>&1
if [ "$ok" != 1 ]; then
  echo "❌ a new Queue with a dead-letter setting did not get its dead-letter queue within 15 seconds"
  exit 1
fi
echo "✅ a new Queue gets its dead-letter queue"
exit 0
exit 1

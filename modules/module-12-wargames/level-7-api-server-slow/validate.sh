#!/bin/bash
NS=${NS:-k8smissions}
. ../_fixtures/lib.sh
fail=0
ensure_probe || { bad "could not start the probe pod"; exit 1; }

if [ "$(ready_count app=config-guard)" -ge 1 ]; then ok "the config-guard backend is Ready"; else bad "the config-guard backend has no Ready pod"; fail=1; fi

# create latency, three samples
TIMEFORMAT=%R
slow=0; failed=0
for i in 1 2 3; do
  t=$( { time kubectl -n "$NS" create configmap "lat-$RANDOM-$i" --from-literal=a=b >/dev/null 2>&1; } 2>&1 )
  rc=$?
  last=$(kubectl -n "$NS" get cm -o name 2>/dev/null | grep -c '^configmap/lat-')
  if [ "$last" -ge "$i" ] && awk -v t="$t" 'BEGIN{exit !(t<2.0)}'; then :; else slow=$((slow + 1)); fi
done
kubectl -n "$NS" delete cm -l '!k8smissions/managed' --field-selector metadata.name!=kube-root-ca.crt >/dev/null 2>&1 || true
for n in $(kubectl -n "$NS" get cm -o name 2>/dev/null | grep '^configmap/lat-'); do kubectl -n "$NS" delete "$n" --wait=false >/dev/null 2>&1; done
if [ "$slow" = 0 ]; then ok "ConfigMaps are created quickly (3 of 3 under 2s)"; else bad "$slow of 3 ConfigMap creations were slow or failed (last: ${t}s)"; fail=1; fi

# the policy still bites, with the webhook's own message
out=$(kubectl -n "$NS" create -f - 2>&1 <<'YAML'
apiVersion: v1
kind: ConfigMap
metadata:
  name: unreviewed-check
  labels: {unreviewed: "true"}
data: {a: b}
YAML
)
if echo "$out" | grep -q "config-guard: ConfigMaps labelled unreviewed=true are not allowed"; then
  ok "config-guard still refuses unreviewed ConfigMaps"
else
  bad "an unreviewed ConfigMap was not refused by config-guard (${out:0:100})"; fail=1
  kubectl -n "$NS" delete cm unreviewed-check --ignore-not-found >/dev/null 2>&1
fi

# the noisy client
if [ "$(ready_count app=inventory-sync)" -ge 1 ]; then
  rate=$(pcurl http://inventory-sync/ | jq -r '.requests_per_sec // 9999' 2>/dev/null)
  if awk -v r="${rate:-9999}" 'BEGIN{exit !(r<5)}'; then ok "inventory-sync sends ${rate} requests per second"; else bad "inventory-sync sends ${rate:-?} requests per second (need under 5)"; fail=1; fi
else
  bad "inventory-sync is not running"; fail=1
fi

[ "$fail" = 0 ] && exit 0
exit 1

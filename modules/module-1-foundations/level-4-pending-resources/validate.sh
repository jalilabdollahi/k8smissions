#!/bin/bash
NS=${NS:-k8smissions}
k() { kubectl -n "$NS" "$@"; }

if ! k get pod report-builder >/dev/null 2>&1; then
  echo "❌ Pod report-builder does not exist"
  exit 1
fi
phase=$(k get pod report-builder -o jsonpath='{.status.phase}')
node=$(k get pod report-builder -o jsonpath='{.spec.nodeName}')
if [ "$phase" != "Running" ] || [ -z "$node" ]; then
  echo "❌ Pod report-builder is $phase and has no node"
  exit 1
fi
echo "✅ Pod report-builder is Running on $node"

cpu=$(k get pod report-builder -o jsonpath='{.spec.containers[0].resources.requests.cpu}')
ok=$(python3 -c '
import sys
v=sys.argv[1]
try:
    c=float(v[:-1])/1000 if v.endswith("m") else float(v)
except Exception:
    c=0
print("yes" if c>=0.25 else "no")' "${cpu:-0}")
if [ "$ok" != "yes" ]; then
  echo "❌ report-builder must keep a CPU request of at least 250m (it is '${cpu:-none}')"
  exit 1
fi
echo "✅ CPU request is still set ($cpu)"

sleep 12
if [ "$(k get pod report-builder -o jsonpath='{.status.containerStatuses[0].ready}')" != "true" ] \
   || [ "$(k get pod report-builder -o jsonpath='{.status.containerStatuses[0].restartCount}')" != "0" ]; then
  echo "❌ report-builder is not Ready or has restarted"
  exit 1
fi
echo "✅ report-builder stayed Ready for 12s"
exit 0
exit 1

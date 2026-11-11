#!/bin/bash
NS=${NS:-k8smissions}
k() { kubectl -n "$NS" "$@"; }

if ! k get deploy catalog-indexer >/dev/null 2>&1; then
  echo "❌ Deployment catalog-indexer does not exist"
  exit 1
fi

python3 - "$NS" <<'PY'
import json, subprocess, sys
d = json.loads(subprocess.check_output(["kubectl", "-n", sys.argv[1], "get", "deploy", "catalog-indexer", "-o", "json"]))
c = d["spec"]["template"]["spec"]["containers"][0]
live, start = c.get("livenessProbe"), c.get("startupProbe")
if not live:
    print("❌ the liveness probe was removed: a hung indexer would never be restarted")
    sys.exit(1)
steady = live.get("periodSeconds", 10) * live.get("failureThreshold", 3)
if steady > 60:
    print("❌ a hung indexer would take %ds to be restarted (period x threshold); the limit is 60s" % steady)
    sys.exit(1)
window = live.get("initialDelaySeconds", 0)
if start:
    window = max(window, start.get("initialDelaySeconds", 0) + start.get("periodSeconds", 10) * start.get("failureThreshold", 3))
if window < 60:
    print("❌ the indexer is only protected for %ds after start, loading takes about 55s plus the pod start" % window)
    sys.exit(1)
print("✅ start-up is protected for %ds and a hung indexer is still caught within %ds" % (window, steady))
PY
[ $? -eq 0 ] || exit 1

if ! k wait --for=condition=Available deploy/catalog-indexer --timeout=75s >/dev/null 2>&1; then
  echo "❌ catalog-indexer is not available yet"
  k get pods -l app=catalog-indexer --no-headers | sed 's/^/   /'
  exit 1
fi
bad=0
n=0
for p in $(../_fixtures/live-pods.sh app=catalog-indexer); do
  n=$((n + 1))
  st=$(k get pod "$p" -o jsonpath='{.status.containerStatuses[0].ready}/{.status.containerStatuses[0].restartCount}')
  [ "$st" = "true/0" ] || { echo "❌ $p ready/restarts is $st"; bad=1; }
done
if [ "$bad" -ne 0 ] || [ "$n" -ne 2 ]; then
  [ "$n" -eq 2 ] || echo "❌ expected 2 live catalog-indexer pods, found $n"
  exit 1
fi
echo "✅ both pods are Ready and have never restarted"

../_fixtures/ensure-probe.sh
out=$(k exec probe -- curl -s --max-time 5 http://catalog-indexer/ 2>/dev/null)
if [ "$out" != "catalog-indexer: 48210 products indexed" ]; then
  echo "❌ Service catalog-indexer did not return the index status (got: ${out:-nothing})"
  exit 1
fi
echo "✅ Service catalog-indexer answers"
exit 0
exit 1

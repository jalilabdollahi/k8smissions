#!/bin/bash
NS=${NS:-k8smissions}
k() { kubectl -n "$NS" "$@"; }

scraper=$(k get deploy prom-lite -o jsonpath='{.metadata.generation}/{.status.readyReplicas}' 2>/dev/null)
if [ "$scraper" != "1/1" ]; then
  echo "❌ the scraper Deployment prom-lite must stay as deployed and Ready (found generation/ready: ${scraper:-gone})"
  exit 1
fi
pay=$(k get deploy payments-api -o jsonpath='{.spec.replicas}/{.status.readyReplicas}/{.status.replicas}' 2>/dev/null)
if [ "$pay" != "2/2/2" ]; then
  echo "❌ payments-api needs 2 Ready replicas (found: ${pay:-none})"
  exit 1
fi
echo "✅ prom-lite is untouched and payments-api has 2 Ready replicas"

../_fixtures/ensure-probe.sh
pods=$(../_fixtures/live-pods.sh app=payments-api | sort | tr '\n' ' ')
report=""
for i in $(seq 1 10); do
  json=$(k exec probe -- curl -s --max-time 4 http://prom-lite:9090/targets 2>/dev/null)
  report=$(PODS="$pods" python3 -c '
import json, os, sys, time
want = os.environ["PODS"].split()
try:
    targets = json.loads(sys.stdin.read() or "[]")
except ValueError:
    targets = []
mine = {t["pod"]: t for t in targets if t.get("job") == "payments-api"}
problems = []
for pod in want:
    t = mine.get(pod)
    if not t:
        problems.append("%s is not a scrape target" % pod)
    elif t.get("health") != "up":
        problems.append("%s is down: %s (%s)" % (pod, t.get("lastError"), t.get("url")))
    elif not t.get("samples", {}).get("app_orders_total", 0) > 0 or time.time() - t.get("lastScrape", 0) > 20:
        problems.append("%s has no fresh app_orders_total sample" % pod)
print("; ".join(problems))
' <<<"$json")
  [ -z "$report" ] && [ -n "$pods" ] && break
  sleep 4
done
if [ -n "$report" ] || [ -z "$pods" ]; then
  echo "❌ prom-lite does not yet scrape payments-api: ${report:-no live pods}"
  exit 1
fi
echo "✅ prom-lite scraped app_orders_total from both payments-api pods"
exit 0
exit 1

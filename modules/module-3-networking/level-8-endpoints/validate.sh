#!/bin/bash
NS=${NS:-k8smissions}
k() { kubectl -n "$NS" "$@"; }

probe=$(k get deploy search-api -o jsonpath='{.spec.template.spec.containers[?(@.name=="search-api")].readinessProbe}' 2>/dev/null)
if [ -z "$probe" ]; then
  echo "❌ search-api no longer has a readiness probe"
  exit 1
fi
r=$(k get deploy search-api -o jsonpath='{.status.readyReplicas}' 2>/dev/null)
if [ "${r:-0}" -ne 4 ]; then
  echo "❌ search-api: ${r:-0} of 4 pods Ready"
  exit 1
fi
restarts=$(k get pods -l app=search-api -o jsonpath='{range .items[*]}{range .status.containerStatuses[*]}{.restartCount}{"\n"}{end}{end}' | awk '{s+=$1} END {print s+0}')
if [ "$restarts" -ne 0 ]; then
  echo "❌ search-api pods have $restarts container restarts in total"
  exit 1
fi
echo "✅ 4 search-api pods are Ready with no restarts"

n=$(k get endpointslices -l kubernetes.io/service-name=search -o jsonpath='{range .items[*].endpoints[?(@.conditions.ready==true)]}{.addresses[0]}{"\n"}{end}' | grep -c .)
if [ "$n" -ne 4 ]; then
  echo "❌ Service search has $n ready endpoints, expected 4"
  exit 1
fi
echo "✅ Service search has 4 ready endpoints"

out=$(k exec probe -- sh -c 'for i in $(seq 12); do curl -s --max-time 3 "http://search/query?q=a"; done' 2>/dev/null)
good=$(echo "$out" | grep -c '^index_docs: 1200$')
if [ "$good" -ne 12 ]; then
  echo "❌ search: only $good of 12 queries returned the index"
  exit 1
fi
echo "✅ search answers every query with the full index"
exit 0
exit 1

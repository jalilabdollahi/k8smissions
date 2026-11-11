#!/bin/bash
NS=${NS:-k8smissions}
k() { kubectl -n "$NS" "$@"; }

ready=$(k get deploy thumb-api -o jsonpath='{.status.readyReplicas}' 2>/dev/null)
if [ "${ready:-0}" -ne 2 ]; then
  echo "❌ Deployment thumb-api: ${ready:-0} of 2 replicas Ready"
  exit 1
fi
restarts=$(k get pods -l app=thumb-api -o jsonpath='{range .items[*]}{.status.containerStatuses[0].restartCount}{"\n"}{end}' | grep -vc '^0$')
if [ "$restarts" != "0" ]; then
  echo "❌ thumb-api pods are restarting"
  exit 1
fi
echo "✅ both thumb-api replicas are Ready and stable"

eps=$(k get endpointslices -l kubernetes.io/service-name=thumb-api -o jsonpath='{range .items[*].endpoints[*]}{.addresses[0]}{"\n"}{end}' | grep -c .)
if [ "$eps" -lt 2 ]; then
  echo "❌ Service thumb-api has only $eps endpoint(s)"
  exit 1
fi
echo "✅ Service thumb-api has $eps endpoints"

out=$(k exec probe -- sh -c 'for i in 1 2 3 4 5 6 7 8; do curl -s --max-time 3 http://thumb-api; done' 2>/dev/null)
if [ "$(echo "$out" | grep -c 'thumbnailer ready')" -ne 8 ]; then
  echo "❌ only $(echo "$out" | grep -c 'thumbnailer ready') of 8 requests to thumb-api:80 succeeded"
  exit 1
fi
echo "✅ 8 of 8 requests to thumb-api:80 succeeded"
exit 0
exit 1

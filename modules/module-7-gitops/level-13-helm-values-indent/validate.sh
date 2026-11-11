#!/bin/bash
NS=${NS:-k8smissions}

if ! helm -n "$NS" status search 2>/dev/null | grep -q '^STATUS: deployed'; then
  echo "❌ Helm release search is not in status deployed"
  exit 1
fi
img=$(kubectl -n "$NS" get deploy search -o jsonpath='{.spec.template.spec.containers[0].image}' 2>/dev/null)
if [ "$img" != "hashicorp/http-echo:1.0" ]; then
  echo "❌ Deployment search runs image '${img:-none}', not the 1.0 build"
  exit 1
fi
echo "✅ release search is deployed and Deployment search runs $img"

kubectl -n "$NS" rollout status deploy/search --timeout=40s >/dev/null 2>&1
ready=$(kubectl -n "$NS" get deploy search -o jsonpath='{.status.readyReplicas}' 2>/dev/null)
total=$(kubectl -n "$NS" get pods -l app=search --no-headers 2>/dev/null | grep -c .)
if [ "${ready:-0}" -ne 2 ] || [ "$total" -ne 2 ]; then
  echo "❌ Deployment search: ${ready:-0} Ready, $total pods in total (expected 2 and 2)"
  exit 1
fi
echo "✅ 2 search pods Ready"

out=$(kubectl -n "$NS" exec probe -- sh -c 'for i in $(seq 20); do curl -s --max-time 2 http://search; echo; done' 2>/dev/null)
good=$(echo "$out" | grep -c '^search prod: ranking v1.0$')
if [ "$good" -ne 20 ]; then
  echo "❌ Service search: only $good of 20 requests returned the new ranking"
  exit 1
fi
echo "✅ Service search answers 20 of 20 requests"
exit 0
exit 1

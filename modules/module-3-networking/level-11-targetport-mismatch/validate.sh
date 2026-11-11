#!/bin/bash
NS=${NS:-k8smissions}
k() { kubectl -n "$NS" "$@"; }

ready=$(k get deploy checkout -o jsonpath='{.status.readyReplicas}' 2>/dev/null)
if [ "${ready:-0}" -ne 3 ]; then
  echo "❌ Deployment checkout: ${ready:-0} of 3 pods Ready"
  exit 1
fi
echo "✅ checkout has 3 Ready pods"

if ! k get svc checkout >/dev/null 2>&1; then
  echo "❌ Service checkout does not exist"
  exit 1
fi

out=$(k exec probe -- sh -c 'for i in $(seq 30); do curl -s --max-time 2 http://checkout; done' 2>/dev/null)
good=$(echo "$out" | grep -c 'checkout v4.2')
old=$(echo "$out" | grep -c 'checkout v4.1')
if [ "$old" -gt 0 ]; then
  echo "❌ $old of 30 requests were answered by release 4.1: the release has to stay"
  exit 1
fi
if [ "$good" -ne 30 ]; then
  echo "❌ checkout: only $good of 30 requests were answered by release 4.2"
  exit 1
fi
echo "✅ checkout: 30 of 30 requests answered by release 4.2"
exit 0
exit 1

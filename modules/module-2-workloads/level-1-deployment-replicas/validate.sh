#!/bin/bash
NS=${NS:-k8smissions}
k() { kubectl -n "$NS" "$@"; }

if ! k get deploy reports >/dev/null 2>&1; then
  echo "❌ Deployment reports does not exist"
  exit 1
fi

avail=$(k get deploy reports -o jsonpath='{.status.availableReplicas}' 2>/dev/null)
if [ "${avail:-0}" -ne 3 ]; then
  echo "❌ Deployment reports: ${avail:-0} of 3 replicas available"
  exit 1
fi
echo "✅ Deployment reports has 3 available replicas"

# Every pod must run as a ServiceAccount that really exists.
for sa in $(k get pods -l app=reports -o jsonpath='{range .items[*]}{.spec.serviceAccountName}{"\n"}{end}' | sort -u); do
  if ! k get sa "$sa" >/dev/null 2>&1; then
    echo "❌ pods run as ServiceAccount $sa, which does not exist"
    exit 1
  fi
done
echo "✅ the pods run as a ServiceAccount that exists"

out=$(k exec probe -- sh -c 'for i in $(seq 20); do curl -s --max-time 2 -o /dev/null -w "%{http_code}\n" http://reports; done' 2>/dev/null)
ok=$(echo "$out" | grep -c '^200$')
if [ "$ok" -ne 20 ]; then
  echo "❌ reports: only $ok of 20 requests returned 200"
  exit 1
fi
echo "✅ reports: 20 of 20 requests returned 200"
exit 0
exit 1

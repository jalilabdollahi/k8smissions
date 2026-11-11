#!/bin/bash
NS=${NS:-k8smissions}
k() { kubectl -n "$NS" "$@"; }

if ! k get secret reports-db >/dev/null 2>&1; then
  echo "❌ Secret reports-db no longer exists"
  exit 1
fi
ready=$(k get deploy reports-api -o jsonpath='{.status.readyReplicas}' 2>/dev/null)
if [ "${ready:-0}" -ne 2 ]; then
  echo "❌ reports-api: ${ready:-0} of 2 pods Ready"
  k get pods -l app=reports-api --no-headers 2>/dev/null | awk '{print "   " $1 " " $3}'
  exit 1
fi
echo "✅ reports-api has 2 Ready pods"

bad=$(k get pods -l app=reports-api -o jsonpath='{range .items[*]}{.status.containerStatuses[0].restartCount}{"\n"}{end}' | grep -vc '^0$')
if [ "$bad" != "0" ]; then
  echo "❌ reports-api pods have restarted"
  exit 1
fi

out=$(k exec probe -- sh -c 'for i in 1 2 3 4 5 6; do curl -s --max-time 4 http://reports-api; done' 2>/dev/null)
if [ "$(echo "$out" | grep -c '^db: authenticated$')" -ne 6 ]; then
  echo "❌ Service reports-api answered: $(echo "$out" | sort | uniq -c | tr '\n' ' ')"
  exit 1
fi
echo "✅ reports-api authenticates against the database 6 times out of 6"
exit 0
exit 1

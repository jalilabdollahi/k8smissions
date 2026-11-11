#!/bin/bash
NS=${NS:-k8smissions}
k() { kubectl -n "$NS" "$@"; }

pods=$(k get pods -l app=reporter --field-selector=status.phase=Running -o jsonpath='{range .items[*]}{.metadata.name} {.metadata.deletionTimestamp}{"\n"}{end}' 2>/dev/null | awk 'NF==1{print $1}')
n=$(echo "$pods" | grep -c .)
if [ "$n" -ne 2 ]; then
  echo "❌ reporter: $n running pods, expected 2"
  exit 1
fi
for p in $pods; do
  ready=$(k get pod "$p" -o jsonpath='{.status.containerStatuses[0].ready}')
  restarts=$(k get pod "$p" -o jsonpath='{.status.containerStatuses[0].restartCount}')
  if [ "$ready" != "true" ] || [ "$restarts" != "0" ]; then
    echo "❌ $p: ready=$ready restarts=$restarts"
    exit 1
  fi
done
echo "✅ both reporter pods are Ready with no restarts"

vip=$(k get svc ledger-db -o jsonpath='{.spec.clusterIP}' 2>/dev/null)
for p in $pods; do
  got=$(k exec "$p" -- python -c "import socket;print(socket.gethostbyname('ledger-db'))" 2>/dev/null)
  if [ -z "$vip" ] || [ "$got" != "$vip" ]; then
    echo "❌ $p: 'ledger-db' resolves to '${got:-nothing}', not the Service address"
    exit 1
  fi
  ip=$(k get pod "$p" -o jsonpath='{.status.podIP}')
  st=$(k exec probe -- curl -s --max-time 5 "http://$ip:8080/" 2>/dev/null)
  if [ "$st" != "db=ok" ]; then
    echo "❌ $p reports '${st:-no answer}'"
    exit 1
  fi
  echo "✅ $p resolves ledger-db and reports db=ok"
done
exit 0
exit 1

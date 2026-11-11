#!/bin/bash
NS=${NS:-k8smissions}
k() { kubectl -n "$NS" "$@"; }

if ! k get statefulset ledger-db >/dev/null 2>&1; then
  echo "❌ there is no StatefulSet named ledger-db"
  exit 1
fi
if ! k get svc ledger-db >/dev/null 2>&1; then
  echo "❌ Service ledger-db does not exist"
  exit 1
fi

# Pods that still belong to a ReplicaSet (the old Deployment) and match the app.
old=$(k get pods -l app=ledger-db -o jsonpath='{range .items[*]}{.metadata.ownerReferences[0].kind}{"\n"}{end}' | grep -c '^ReplicaSet$')
if [ "$old" -ne 0 ]; then
  echo "❌ $old pod(s) from the old Deployment are still running behind Service ledger-db"
  exit 1
fi
echo "✅ no Deployment pods are left"

if ! k wait --for=condition=Ready pod/ledger-db-0 pod/ledger-db-1 pod/ledger-db-2 --timeout=45s >/dev/null 2>&1; then
  echo "❌ pods ledger-db-0, ledger-db-1 and ledger-db-2 are not all Ready"
  exit 1
fi
echo "✅ ledger-db-0, ledger-db-1 and ledger-db-2 are Ready"

resolve() {  # member -> body served at <member>.ledger-db, retrying for DNS to catch up
  for _ in 1 2 3 4 5 6 7 8; do
    b=$(k exec probe -- curl -s --max-time 2 "http://$1.ledger-db:8080" 2>/dev/null | tr -d '[:space:]')
    [ -n "$b" ] && { echo "$b"; return 0; }
    sleep 2
  done
  return 1
}

for i in 0 1 2; do
  b=$(resolve "ledger-db-$i")
  if [ "$b" != "ledger-db-$i" ]; then
    echo "❌ ledger-db-$i.ledger-db did not answer as ledger-db-$i (got '${b:-nothing}')"
    exit 1
  fi
done
echo "✅ every member answers at <pod>.ledger-db"

uid_before=$(k get pod ledger-db-1 -o jsonpath='{.metadata.uid}')
k delete pod ledger-db-1 --wait=true >/dev/null 2>&1
if ! k wait --for=condition=Ready pod/ledger-db-1 --timeout=45s >/dev/null 2>&1; then
  echo "❌ ledger-db-1 did not come back after being deleted"
  exit 1
fi
uid_after=$(k get pod ledger-db-1 -o jsonpath='{.metadata.uid}')
b=$(resolve ledger-db-1)
if [ "$uid_before" = "$uid_after" ] || [ "$b" != "ledger-db-1" ]; then
  echo "❌ the replacement for ledger-db-1 does not keep its name and DNS identity"
  exit 1
fi
echo "✅ a deleted member returns as ledger-db-1 at ledger-db-1.ledger-db"
exit 0
exit 1

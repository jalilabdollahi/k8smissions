#!/bin/bash
NS=${NS:-k8smissions}
k() { kubectl -n "$NS" "$@"; }

sn=$(k get statefulset db -o jsonpath='{.spec.serviceName}' 2>/dev/null)
if [ "$sn" != "db-hs" ]; then
  echo "❌ StatefulSet db is missing or its serviceName is not db-hs"
  exit 1
fi
ready=$(k get statefulset db -o jsonpath='{.status.readyReplicas}')
if [ "${ready:-0}" -ne 3 ]; then
  echo "❌ StatefulSet db: ${ready:-0} of 3 members Ready"
  exit 1
fi
echo "✅ StatefulSet db has 3 Ready members"

# Client traffic must keep going through the normal Service.
cip=$(k get svc db -o jsonpath='{.spec.clusterIP}' 2>/dev/null)
if [ -z "$cip" ] || [ "$cip" = "None" ]; then
  echo "❌ Service db must stay a normal Service with a cluster IP for client traffic"
  exit 1
fi
body=$(k exec probe -- curl -s --max-time 3 http://db 2>/dev/null | tr -d '[:space:]')
case "$body" in
  db-[012]) echo "✅ Service db answers through its cluster IP" ;;
  *) echo "❌ Service db does not answer (got '${body:-nothing}')"; exit 1 ;;
esac

resolve() {
  for _ in 1 2 3 4 5 6 7 8 9 10 11 12; do
    b=$(k exec probe -- curl -s --max-time 2 "http://$1.db-hs:8080" 2>/dev/null | tr -d '[:space:]')
    [ -n "$b" ] && { echo "$b"; return 0; }
    sleep 3
  done
  return 1
}
for i in 0 1 2; do
  b=$(resolve "db-$i")
  if [ "$b" != "db-$i" ]; then
    echo "❌ db-$i.db-hs does not resolve to member db-$i (got '${b:-nothing}')"
    exit 1
  fi
done
echo "✅ db-0.db-hs, db-1.db-hs and db-2.db-hs all answer"

if ! k wait --for=condition=Available deploy/db-monitor --timeout=30s >/dev/null 2>&1; then
  echo "❌ db-monitor is still not Ready"
  exit 1
fi
echo "✅ db-monitor is Ready"
exit 0
exit 1

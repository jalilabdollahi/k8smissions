#!/bin/bash
NS=${NS:-k8smissions}
k() { kubectl -n "$NS" "$@"; }
CRD=workloads.platform.acme.io

if [ "$(kubectl get crd $CRD -o jsonpath='{.status.conditions[?(@.type=="Established")].status}' 2>/dev/null)" != "True" ]; then
  echo "❌ the Workload CRD is missing or not Established"
  exit 1
fi

try() {  # try <replicas> <tier> [extra spec lines]: "ok" or "rejected"
  if k create --dry-run=server -f - >/dev/null 2>&1 <<Y
apiVersion: platform.acme.io/v1
kind: Workload
metadata: {name: probe-wl}
spec:
  replicas: $1
  tier: $2
$3
Y
  then echo ok; else echo rejected; fi
}

fail=0
[ "$(try -999 silver)" = rejected ] || { echo "❌ a Workload with replicas -999 is accepted"; fail=1; }
[ "$(try '"lots"' silver)" = rejected ] || { echo "❌ a Workload with replicas \"lots\" is accepted"; fail=1; }
[ "$(try 3 gold-plated)" = rejected ] || { echo "❌ a Workload with tier gold-plated is accepted"; fail=1; }
[ "$fail" = 0 ] && echo "✅ nonsense Workloads are rejected"

if [ "$(try 3 silver '  owner: probe-team
  costCenter: CC-9999')" != ok ]; then
  echo "❌ a valid Workload is rejected"
  fail=1
else
  echo "✅ a valid Workload is accepted"
fi
cc=$(k create --dry-run=server -o jsonpath='{.spec.owner}/{.spec.costCenter}' -f - 2>/dev/null <<'Y'
apiVersion: platform.acme.io/v1
kind: Workload
metadata: {name: probe-wl}
spec: {replicas: 3, tier: silver, owner: probe-team, costCenter: CC-9999}
Y
)
if [ "$cc" != "probe-team/CC-9999" ]; then
  echo "❌ new Workloads lose their owner and costCenter fields (stored as '$cc')"
  fail=1
fi

for row in "search-indexer 4/silver/search-team/CC-4411" "thumbnailer 2/bronze/media-team/CC-2087"; do
  set -- $row
  got=$(k get workload "$1" -o jsonpath='{.spec.replicas}/{.spec.tier}/{.spec.owner}/{.spec.costCenter}' 2>/dev/null)
  if [ "$got" != "$2" ]; then
    echo "❌ Workload $1 no longer reads as $2 (found '${got:-nothing}')"
    fail=1
  fi
done
[ "$fail" = 0 ] || exit 1
echo "✅ the live Workloads kept all their data"
exit 0
exit 1

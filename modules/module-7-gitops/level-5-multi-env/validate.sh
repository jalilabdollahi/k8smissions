#!/bin/bash
NS=${NS:-k8smissions}
app() { kubectl -n argocd get app "$1" -o jsonpath="$2" 2>/dev/null; }

dev_ok=$(kubectl -n shop-dev get deploy shop -o jsonpath='{.status.readyReplicas}/{.spec.replicas}/{.spec.template.spec.containers[0].env[0].value}' 2>/dev/null)
if [ "$dev_ok" != "1/1/debug" ] || [ "$(app shop-dev '{.status.sync.status}/{.status.health.status}')" != "Synced/Healthy" ]; then
  echo "❌ the dev side changed: shop-dev app/workload is '${dev_ok:-missing}', it must stay 1 replica at debug"
  exit 1
fi

sync=$(app shop-prod '{.status.sync.status}'); health=$(app shop-prod '{.status.health.status}')
if [ "$sync" != "Synced" ] || [ "$health" != "Healthy" ]; then
  echo "❌ Application shop-prod: sync=${sync:-none} health=${health:-none}"
  exit 1
fi
echo "✅ Application shop-prod is Synced and Healthy, shop-dev untouched"

ready=$(kubectl -n shop-prod get deploy shop -o jsonpath='{.status.readyReplicas}' 2>/dev/null)
want=$(kubectl -n shop-prod get deploy shop -o jsonpath='{.spec.replicas}' 2>/dev/null)
if [ "${ready:-0}" -ne 3 ] || [ "${want:-0}" -ne 3 ]; then
  echo "❌ production shop: ${ready:-0} Ready of ${want:-0} desired replicas, expected 3"
  exit 1
fi
echo "✅ production runs 3 Ready replicas"

lim=$(kubectl -n shop-prod get deploy shop -o jsonpath='{.spec.template.spec.containers[0].resources.limits.cpu}/{.spec.template.spec.containers[0].resources.limits.memory}' 2>/dev/null)
case "$lim" in
  /*|*/) echo "❌ production container limits are incomplete: cpu/memory = '$lim'"; exit 1 ;;
esac
echo "✅ production container has CPU and memory limits ($lim)"

out=$(kubectl -n "$NS" exec probe -- sh -c 'for i in $(seq 15); do curl -s --max-time 2 http://shop.shop-prod/config; echo; done' 2>/dev/null)
good=$(echo "$out" | grep -c '"log_level": "info"')
if [ "$good" -ne 15 ]; then
  echo "❌ production /config reports log_level info on only $good of 15 requests"
  exit 1
fi
echo "✅ production /config reports log_level info on every request"
exit 0
exit 1

#!/bin/bash
NS=${NS:-k8smissions}
k() { kubectl -n "$NS" "$@"; }

if [ "$(k get cm pricing-config -o jsonpath='{.data.TAX_RATE}' 2>/dev/null)" != "0.20" ]; then
  echo "❌ ConfigMap pricing-config must keep TAX_RATE 0.20"
  exit 1
fi
if ! k get deploy pricing -o yaml 2>/dev/null | grep -q 'name: pricing-config'; then
  echo "❌ Deployment pricing no longer reads its settings from ConfigMap pricing-config"
  exit 1
fi
echo "✅ the rate lives in ConfigMap pricing-config and pricing reads it from there"

ready=$(k get deploy pricing -o jsonpath='{.status.readyReplicas}' 2>/dev/null)
upd=$(k get deploy pricing -o jsonpath='{.status.updatedReplicas}' 2>/dev/null)
if [ "${ready:-0}" -ne 2 ] || [ "${upd:-0}" -ne 2 ]; then
  echo "❌ pricing: ${ready:-0} Ready, ${upd:-0} updated, expected 2 of each"
  exit 1
fi
echo "✅ pricing has 2 Ready pods"

out=$(k exec probe -- sh -c 'for i in 1 2 3 4 5 6 7 8 9 10; do curl -s --max-time 3 http://pricing; echo; done' 2>/dev/null)
good=$(echo "$out" | grep -c '"tax_rate": "0.20"')
if [ "$good" -ne 10 ]; then
  echo "❌ only $good of 10 responses report tax_rate 0.20"
  exit 1
fi
echo "✅ 10 of 10 responses report tax_rate 0.20"
exit 0
exit 1

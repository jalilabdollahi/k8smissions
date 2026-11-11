#!/bin/bash
NS=${NS:-k8smissions}
. ../_fixtures/lib.sh
k() { kubectl -n "$NS" "$@"; }

ssd=$(worker_n 1); hdd=$(worker_n 2)
if [ "$(kubectl get node "$ssd" -o jsonpath='{.metadata.labels.disktype}')" != "ssd" ] || \
   [ "$(kubectl get node "$hdd" -o jsonpath='{.metadata.labels.disktype}')" != "hdd" ]; then
  echo "❌ the disktype labels were changed; they describe the real disks and must stay accurate"
  exit 1
fi
rep=$(k get deploy inference-gateway -o jsonpath='{.spec.replicas}' 2>/dev/null)
pods=$(k get pods -l app=inference-gateway -o json | jq '[.items[] | select(.metadata.deletionTimestamp==null)]')
if [ "${rep:-0}" -ne 2 ] || [ "$(echo "$pods" | jq length)" -ne 2 ]; then
  echo "❌ inference-gateway must run 2 pods (found $(echo "$pods" | jq length))"
  exit 1
fi
running=$(echo "$pods" | jq '[.[] | select(.status.phase=="Running")] | length')
if [ "$running" -ne 2 ]; then
  echo "❌ inference-gateway: $running of 2 pods Running"
  exit 1
fi
echo "✅ inference-gateway: 2 of 2 pods Running"

on_ssd=$(echo "$pods" | jq --arg n "$ssd" '[.[] | select(.spec.nodeName==$n)] | length')
if [ "$on_ssd" -ne 2 ]; then
  echo "❌ only $on_ssd of 2 pods run on the SSD node; the model weights need that disk"
  exit 1
fi
echo "✅ both pods run on the SSD node"
exit 0
exit 1

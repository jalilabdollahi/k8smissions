#!/bin/bash
NS=${NS:-k8smissions}
. ../_fixtures/lib.sh
k() { kubectl -n "$NS" "$@"; }

spot=$(kubectl get nodes -l lifecycle=spot -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)
od=$(kubectl get nodes -l lifecycle=on-demand -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)
if [ -z "$spot" ] || [ -z "$od" ]; then
  echo "❌ the nodes' lifecycle labels were changed; they describe the real hardware and must stay"
  exit 1
fi
if ! kubectl get node "$spot" -o json | jq -e '.spec.taints // [] | any(.key=="spot-reclaimed")' >/dev/null; then
  echo "❌ the spot-reclaimed taint is gone from $spot: that node is gone for good"
  exit 1
fi
if ! kubectl get node "$od" -o json | jq -e '.spec.taints // [] | any(.key=="lifecycle" and .value=="on-demand")' >/dev/null; then
  echo "❌ the on-demand taint is gone from $od: it keeps ordinary workloads off paid capacity"
  exit 1
fi
echo "✅ both node taints are intact"

rep=$(k get deploy render-farm -o jsonpath='{.spec.replicas}' 2>/dev/null)
pods=$(k get pods -l app=render-farm -o json | jq '[.items[] | select(.metadata.deletionTimestamp==null)]')
if [ "${rep:-0}" -ne 4 ] || [ "$(echo "$pods" | jq length)" -ne 4 ]; then
  echo "❌ render-farm must run exactly 4 pods (found $(echo "$pods" | jq length), replicas ${rep:-none})"
  exit 1
fi
running=$(echo "$pods" | jq '[.[] | select(.status.phase=="Running")] | length')
if [ "$running" -ne 4 ]; then
  echo "❌ render-farm: $running of 4 pods Running"
  exit 1
fi
on_spot=$(echo "$pods" | jq --arg n "$spot" '[.[] | select(.spec.nodeName==$n)] | length')
on_od=$(echo "$pods" | jq --arg n "$od" '[.[] | select(.spec.nodeName==$n)] | length')
if [ "$on_spot" -ne 0 ]; then
  echo "❌ $on_spot render-farm pod(s) landed on the reclaimed spot node"
  exit 1
fi
if [ "$on_od" -ne 4 ]; then
  echo "❌ only $on_od of 4 pods run on the on-demand node"
  exit 1
fi
echo "✅ render-farm: 4 of 4 pods Running on the on-demand node, none on the spot node"
exit 0
exit 1

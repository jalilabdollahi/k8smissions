#!/bin/bash
NS=${NS:-k8smissions}
k() { kubectl -n "$NS" "$@"; }

web=$(k get deploy reports-web -o jsonpath='{.status.readyReplicas}' 2>/dev/null)
cache=$(k get deploy reports-cache -o jsonpath='{.status.readyReplicas}' 2>/dev/null)
if [ "${web:-0}" -ne 3 ] || [ "${cache:-0}" -ne 2 ]; then
  echo "❌ reports-web ${web:-0}/3 Ready, reports-cache ${cache:-0}/2 Ready"
  exit 1
fi
echo "✅ reports-web 3/3 and reports-cache 2/2 are Ready"

live() { k get pods -l "tier=$1" -o json | jq -r '.items[] | select(.metadata.deletionTimestamp==null) | select(.status.phase=="Running") | .spec.nodeName'; }
cache_nodes=$(live cache | sort -u)
web_nodes=$(live web)
if [ -z "$cache_nodes" ] || [ "$(echo "$web_nodes" | grep -c .)" -ne 3 ]; then
  echo "❌ the pods are not settled yet (rollout in progress)"
  exit 1
fi
for n in $web_nodes; do
  if ! echo "$cache_nodes" | grep -qx "$n"; then
    echo "❌ a reports-web pod runs on $n, which has no reports-cache pod"
    exit 1
  fi
done
echo "✅ every reports-web pod shares a node with a reports-cache pod"
exit 0
exit 1

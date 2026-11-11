#!/bin/bash
NS=${NS:-k8smissions}
. ../_fixtures/lib.sh
k() { kubectl -n "$NS" "$@"; }

if ! kubectl get deviceclass gpu.example.com >/dev/null 2>&1; then
  echo "❌ DeviceClass gpu.example.com does not exist"
  exit 1
fi
echo "✅ DeviceClass gpu.example.com exists"

if ! k get deploy lab-notebook >/dev/null 2>&1; then
  echo "❌ Deployment lab-notebook is missing"
  exit 1
fi
pod=$(k get pods -l app=lab-notebook -o json | jq '[.items[] | select(.metadata.deletionTimestamp==null)] | .[0]')
name=$(echo "$pod" | jq -r '.metadata.name // empty')
node=$(echo "$pod" | jq -r '.spec.nodeName // empty')
if [ -z "$name" ] || [ -z "$node" ]; then
  echo "❌ lab-notebook has no scheduled pod yet"
  exit 1
fi
if ! workers | grep -qx "$node"; then
  echo "❌ lab-notebook was placed on $node, which is not a worker"
  exit 1
fi
echo "✅ the pod is scheduled on worker $node"

uid=$(echo "$pod" | jq -r '.metadata.uid')
res=$(k get resourceclaim -o json | jq -c --arg uid "$uid" '[.items[] | select(any(.metadata.ownerReferences[]?; .uid==$uid)) | .status.allocation.devices.results[]?] | .[0] // empty')
if [ -z "$res" ]; then
  echo "❌ the pod's ResourceClaim has no allocation yet"
  exit 1
fi
drv=$(echo "$res" | jq -r .driver); pool=$(echo "$res" | jq -r .pool); dev=$(echo "$res" | jq -r .device)
found=$(kubectl get resourceslice -o json | jq --arg d "$drv" --arg p "$pool" --arg dev "$dev" --arg n "$node" \
  '[.items[] | select(.spec.driver==$d and .spec.pool.name==$p and .spec.nodeName==$n) | .spec.devices[] | select(.name==$dev)] | length')
if [ "$found" -lt 1 ]; then
  echo "❌ the allocated device $dev is not published for node $node"
  exit 1
fi
echo "✅ claim allocated device $dev of driver $drv on $node"
exit 0
exit 1

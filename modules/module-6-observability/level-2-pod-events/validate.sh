#!/bin/bash
NS=${NS:-k8smissions}
k() { kubectl -n "$NS" "$@"; }

if ! k get deploy billing-worker >/dev/null 2>&1; then
  echo "❌ Deployment billing-worker does not exist"
  exit 1
fi
want=$(k get deploy billing-worker -o jsonpath='{.spec.replicas}')
image=$(k get deploy billing-worker -o jsonpath='{.spec.template.spec.containers[0].image}')
if [ "$want" != "2" ] || [ "$image" != "busybox:1.36" ]; then
  echo "❌ billing-worker must keep 2 replicas and its original image (now: $want x $image)"
  exit 1
fi
echo "✅ Deployment billing-worker keeps its replica count and image"

ready=$(k get deploy billing-worker -o jsonpath='{.status.readyReplicas}')
if [ "${ready:-0}" -ne 2 ]; then
  echo "❌ billing-worker: ${ready:-0} of 2 pods Ready"
  exit 1
fi
echo "✅ 2 of 2 pods Ready"

rs=$(k get rs -l app=billing-worker -o jsonpath='{range .items[?(@.status.readyReplicas>0)]}{.metadata.name}{"\n"}{end}' | head -1)
owner=$(k get rs "$rs" -o jsonpath='{.metadata.ownerReferences[0].name}' 2>/dev/null)
sas=$(k get pods -l app=billing-worker -o jsonpath='{range .items[*]}{.spec.serviceAccountName}{"\n"}{end}' | sort -u)
if [ "$owner" != "billing-worker" ] || [ "$sas" != "billing-sa" ]; then
  echo "❌ the running pods must come from the Deployment and run as billing-sa (found: ${sas:-none})"
  exit 1
fi
echo "✅ the pods are Deployment-managed and run as billing-sa"

if [ "$(k auth can-i get pods --as="system:serviceaccount:$NS:billing-sa" 2>/dev/null)" != "no" ] || \
   [ "$(k auth can-i get secrets --as="system:serviceaccount:$NS:billing-sa" 2>/dev/null)" != "no" ]; then
  echo "❌ billing-sa was given permissions it should not have"
  exit 1
fi
echo "✅ billing-sa has no extra permissions"
exit 0
exit 1

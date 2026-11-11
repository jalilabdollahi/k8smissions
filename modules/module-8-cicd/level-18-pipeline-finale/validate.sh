#!/bin/bash
NS=${NS:-k8smissions}
k() { kubectl -n "$NS" "$@"; }
SA="system:serviceaccount:$NS:deploy-sa"
can() { kubectl auth can-i "$@" --as="$SA" 2>/dev/null; }

if ! k get pipeline ship-payments >/dev/null 2>&1 || ! k get sa deploy-sa >/dev/null 2>&1 \
   || ! k get deployment registry >/dev/null 2>&1; then
  echo "❌ Pipeline ship-payments, ServiceAccount deploy-sa or the registry is missing"
  exit 1
fi
run=$(k create -o name -f - <<YAML
apiVersion: tekton.dev/v1
kind: PipelineRun
metadata:
  generateName: verify-payments-
  labels: {verify: pipeline-finale}
spec:
  pipelineRef:
    name: ship-payments
  taskRunTemplate:
    serviceAccountName: deploy-sa
YAML
)
name=${run#*/}
trap 'k delete pipelinerun -l verify=pipeline-finale --wait=false >/dev/null 2>&1' EXIT
for _ in $(seq 1 55); do
  st=$(k get "$run" -o jsonpath='{.status.conditions[0].status}' 2>/dev/null)
  [ "$st" = "True" ] || [ "$st" = "False" ] && break
  sleep 2
done
if [ "$st" != "True" ]; then
  failed=$(k get taskrun -l "tekton.dev/pipelineRun=$name" -o jsonpath='{range .items[?(@.status.conditions[0].status=="False")]}{.metadata.labels.tekton\.dev/pipelineTask}{" "}{end}' 2>/dev/null)
  echo "❌ the run did not Succeed (status '${st:-running}'; failed Task: ${failed:-none yet})"
  exit 1
fi
echo "✅ ship-payments ran clone, push and deploy to the end"

want=$(kubectl -n "$NS" exec deploy/registry -- wget -qO- \
  --header 'Accept: application/vnd.docker.distribution.manifest.v2+json, application/vnd.oci.image.manifest.v1+json' \
  "http://localhost:5000/v2/payments/api/manifests/$name" 2>/dev/null | sha256sum | awk '{print "sha256:" $1}')
tags=$(kubectl -n "$NS" exec deploy/registry -- wget -qO- http://localhost:5000/v2/payments/api/tags/list 2>/dev/null)
if ! echo "$tags" | grep -q "\"$name\""; then
  echo "❌ the registry does not list the tag $name for payments/api"
  exit 1
fi
echo "✅ the registry holds payments/api:$name ($want)"

ok=0
for _ in 1 2 3 4 5 6; do
  body=$(kubectl get --raw "/api/v1/namespaces/payments-prod/services/payments-api:80/proxy/" 2>/dev/null)
  [ "$body" = "payments-api $want" ] && ok=$((ok + 1))
done
if [ "$ok" != "6" ]; then
  echo "❌ Service payments-api in payments-prod answered with the pushed digest in $ok of 6 requests"
  exit 1
fi
echo "✅ payments-api in payments-prod serves the pushed digest"

for what in "get secrets -n payments-prod" "create pods -n payments-prod" "create deployments.apps -n $NS" "delete namespaces"; do
  if [ "$(can $what)" != "no" ]; then
    echo "❌ deploy-sa is allowed to '$what', which the deploy job does not need"
    exit 1
  fi
done
if [ "$(can patch deployments.apps -n payments-prod)" != "yes" ]; then
  echo "❌ deploy-sa cannot patch Deployments in payments-prod"
  exit 1
fi
echo "✅ deploy-sa is confined to deploying in payments-prod"
exit 0
exit 1

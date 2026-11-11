#!/bin/bash
NS=${NS:-k8smissions}
k() { kubectl -n "$NS" "$@"; }
SA="system:serviceaccount:$NS:deploy-sa"
can() { kubectl auth can-i "$@" --as="$SA" 2>/dev/null; }

if ! k get pipeline release-storefront >/dev/null 2>&1; then
  echo "❌ Pipeline release-storefront does not exist"
  exit 1
fi

version="9.$(date +%S).1"
run=$(k create -o name -f - <<YAML
apiVersion: tekton.dev/v1
kind: PipelineRun
metadata:
  generateName: verify-release-
spec:
  pipelineRef:
    name: release-storefront
  params:
  - name: version
    value: "$version"
  taskRunTemplate:
    serviceAccountName: deploy-sa
YAML
)
if [ -z "$run" ]; then
  echo "❌ could not start a run of release-storefront"
  exit 1
fi
trap 'k delete "$run" --wait=false >/dev/null 2>&1' EXIT
for _ in $(seq 1 35); do
  st=$(k get "$run" -o jsonpath='{.status.conditions[0].status}' 2>/dev/null)
  if [ "$st" = "True" ] || [ "$st" = "False" ]; then break; fi
  sleep 2
done
if [ "$st" != "True" ]; then
  pod=$(k get taskrun -l "tekton.dev/pipelineRun=${run#*/}" -o jsonpath='{.items[0].status.podName}' 2>/dev/null)
  err=$(k logs "$pod" -c step-apply 2>/dev/null | grep -i -m1 forbidden | sed 's/.*Error from server/Error from server/' | cut -c1-140)
  echo "❌ the release run as deploy-sa did not Succeed (status: ${st:-still running}) ${err}"
  exit 1
fi
echo "✅ the release run as deploy-sa Succeeded"

out=$(k exec probe -- sh -c 'for i in 1 2 3 4; do curl -s --max-time 4 http://storefront.shop-staging.svc.cluster.local; done' 2>/dev/null)
if [ "$(echo "$out" | grep -c "storefront $version")" != "4" ]; then
  echo "❌ Service storefront in shop-staging does not answer 'storefront $version' on every request"
  exit 1
fi
echo "✅ storefront in shop-staging serves $version"

if [ "$(can get secrets -n shop-staging)" != "no" ] || [ "$(can '*' '*' -n shop-staging)" != "no" ]; then
  echo "❌ deploy-sa can read Secrets (or do everything) in shop-staging; it should only manage Deployments and Services there"
  exit 1
fi
for v in "create deployments.apps" "create services" "patch deployments.apps" "delete pods"; do
  if [ "$(can $v -n shop-prod)" != "no" ]; then
    echo "❌ deploy-sa is allowed to '$v' in shop-prod"
    exit 1
  fi
done
if [ "$(can delete namespaces)" != "no" ] || [ "$(can create clusterrolebindings.rbac.authorization.k8s.io)" != "no" ]; then
  echo "❌ deploy-sa has cluster-wide rights it does not need"
  exit 1
fi
echo "✅ deploy-sa stays out of Secrets, shop-prod and cluster-scoped objects"
exit 0
exit 1

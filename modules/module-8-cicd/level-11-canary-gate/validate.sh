#!/bin/bash
NS=${NS:-k8smissions}
k() { kubectl -n "$NS" "$@"; }

if ! k get pipeline release-checkout >/dev/null 2>&1 || ! k get deployment checkout-stable >/dev/null 2>&1 \
   || ! k get service checkout >/dev/null 2>&1; then
  echo "❌ Pipeline release-checkout, Deployment checkout-stable or Service checkout is missing"
  exit 1
fi
# stuck runs would fight the rehearsal for the same Deployments
for r in $(k get pipelinerun -l tekton.dev/pipeline=release-checkout -o jsonpath='{range .items[?(@.status.conditions[0].status=="Unknown")]}{.metadata.name}{"\n"}{end}' 2>/dev/null); do
  k patch pipelinerun "$r" --type=merge -p '{"spec":{"status":"Cancelled"}}' >/dev/null 2>&1
done

release() { # version mode canary-name
  k create -o name -f - <<YAML
apiVersion: tekton.dev/v1
kind: PipelineRun
metadata:
  generateName: verify-release-
  labels: {verify: canary-gate}
spec:
  pipelineRef:
    name: release-checkout
  taskRunTemplate:
    serviceAccountName: release-sa
  params:
  - {name: version, value: "$1"}
  - {name: canary-mode, value: "$2"}
  - {name: canary-name, value: "$3"}
YAML
}
wait_run() { # name seconds
  for _ in $(seq 1 $(($2 / 2))); do
    s=$(k get "$1" -o jsonpath='{.status.conditions[0].status}' 2>/dev/null)
    [ "$s" = "True" ] || [ "$s" = "False" ] && break
    sleep 2
  done
  echo "$s"
}
trap 'k delete pipelinerun -l verify=canary-gate --wait=false >/dev/null 2>&1; k delete deployment verify-canary-good verify-canary-bad --ignore-not-found --wait=false >/dev/null 2>&1' EXIT

good="v$(date +%s)"
grun=$(release "$good" ok verify-canary-good)
brun=$(release "v-broken" crash verify-canary-bad)
st=$(wait_run "$grun" 70)
if [ "$st" != "True" ]; then
  echo "❌ a release of a healthy build did not Succeed within 70s (status '${st:-still running}')"
  exit 1
fi
promoted=$(k get "$grun" -o jsonpath='{.status.results[?(@.name=="promoted")].value}')
if [ "$promoted" != "true" ]; then
  echo "❌ the release Succeeded but the Pipeline result promoted is '${promoted}'"
  exit 1
fi
echo "✅ the healthy release Succeeded and promoted"
bad=0
for _ in $(seq 1 12); do
  [ "$(k get --raw "/api/v1/namespaces/$NS/services/checkout:80/proxy/" 2>/dev/null)" = "$good" ] || bad=$((bad + 1))
done
if [ "$bad" != "0" ]; then
  echo "❌ Service checkout still gave another answer than $good in $bad of 12 requests"
  exit 1
fi
echo "✅ Service checkout answers $good only"

st=$(wait_run "$brun" 30)
if [ "$st" != "False" ]; then
  echo "❌ a release whose canary never becomes healthy did not end Failed in time (status '${st:-still running}')"
  exit 1
fi
gate=$(k get taskrun -l "tekton.dev/pipelineRun=${brun#*/},tekton.dev/pipelineTask=canary-gate" -o jsonpath='{.items[0].status.conditions[0].status}')
if [ "$gate" != "False" ]; then
  echo "❌ the broken release was expected to fail at the canary-gate Task"
  exit 1
fi
arg=$(k get deployment checkout-stable -o jsonpath='{.spec.template.spec.containers[0].args[1]}')
if [ "$arg" != "-text=$good" ]; then
  echo "❌ checkout-stable was touched by the failed release (args: $arg)"
  exit 1
fi
echo "✅ the broken release ended Failed at canary-gate and checkout-stable stayed on $good"
exit 0
exit 1

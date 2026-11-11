#!/bin/bash
NS=${NS:-k8smissions}
k() { kubectl -n "$NS" "$@"; }

if ! k get pipeline release-ledger >/dev/null 2>&1 || ! k get deployment ledger-api >/dev/null 2>&1; then
  echo "❌ Pipeline release-ledger or Deployment ledger-api is missing"
  exit 1
fi
release() {
  k create -o name -f - <<YAML
apiVersion: tekton.dev/v1
kind: PipelineRun
metadata:
  generateName: verify-ledger-
  labels: {verify: rollout-abort}
spec:
  pipelineRef:
    name: release-ledger
  taskRunTemplate:
    serviceAccountName: releaser
  params:
  - {name: tag, value: "$1"}
YAML
}
wait_run() {
  for _ in $(seq 1 $(($2 / 2))); do
    s=$(k get "$1" -o jsonpath='{.status.conditions[0].status}' 2>/dev/null)
    [ "$s" = "True" ] || [ "$s" = "False" ] && break
    sleep 2
  done
  echo "$s"
}
image() { k get deployment ledger-api -o jsonpath='{.spec.template.spec.containers[0].image}'; }
serves() {
  n=0
  for _ in 1 2 3 4 5 6; do
    [ "$(k get --raw "/api/v1/namespaces/$NS/services/ledger-api:80/proxy/" 2>/dev/null)" = "ledger-ok" ] && n=$((n + 1))
  done
  [ "$n" = "6" ]
}
trap 'k delete pipelinerun -l verify=rollout-abort --wait=false >/dev/null 2>&1' EXIT

cur=$(image); cur=${cur##*:}
if [ "$cur" = "0.2.3" ]; then good=1.0.0; else good=0.2.3; fi
run=$(release "$good")
st=$(wait_run "$run" 60)
if [ "$st" != "True" ] || [ "$(image)" != "hashicorp/http-echo:$good" ]; then
  echo "❌ a release of the good tag $good did not Succeed with the new image running (status '${st:-still running}', image $(image))"
  exit 1
fi
echo "✅ the good release Succeeded and ledger-api runs hashicorp/http-echo:$good"

run=$(release "0.0.0-nosuchtag")
st=$(wait_run "$run" 90)
if [ "$st" != "False" ]; then
  echo "❌ the release with the bad tag did not end Failed (status '${st:-still running}')"
  exit 1
fi
dep=$(k get taskrun -l "tekton.dev/pipelineRun=${run#*/},tekton.dev/pipelineTask=deploy" -o jsonpath='{.items[0].status.conditions[0].status}')
if [ "$dep" != "False" ]; then
  echo "❌ the bad release was expected to fail in the deploy Task"
  exit 1
fi
echo "✅ the bad release ended Failed at deploy"
if [ "$(image)" != "hashicorp/http-echo:$good" ]; then
  echo "❌ ledger-api is still on $(image) after the failed release, not back on hashicorp/http-echo:$good"
  exit 1
fi
if ! k rollout status deployment/ledger-api --timeout=40s >/dev/null 2>&1; then
  echo "❌ ledger-api has not finished rolling back to a healthy state"
  exit 1
fi
avail=$(k get deployment ledger-api -o jsonpath='{.status.availableReplicas}')
if [ "$avail" != "3" ] || ! serves; then
  echo "❌ ledger-api has $avail of 3 replicas available or does not answer through its Service"
  exit 1
fi
echo "✅ ledger-api is back on the previous good image, 3 of 3 replicas serving"
exit 0
exit 1

#!/bin/bash
NS=${NS:-k8smissions}
k() { kubectl -n "$NS" "$@"; }

if ! k get pipeline ship-ledger >/dev/null 2>&1; then
  echo "❌ Pipeline ship-ledger does not exist"
  exit 1
fi

start() {
  k create -o name -f - <<YAML
apiVersion: tekton.dev/v1
kind: PipelineRun
metadata:
  generateName: verify-ship-
  labels:
    verify: test-gate
spec:
  pipelineRef:
    name: ship-ledger
  params:
  - name: suite
    value: $1
YAML
}
trap 'k delete pipelinerun -l verify=test-gate --wait=false >/dev/null 2>&1' EXIT

red=$(start regression); green=$(start smoke)
if [ -z "$red" ] || [ -z "$green" ]; then
  echo "❌ could not start runs of ship-ledger"
  exit 1
fi
for _ in $(seq 1 28); do
  a=$(k get "$red" -o jsonpath='{.status.conditions[0].status}' 2>/dev/null)
  b=$(k get "$green" -o jsonpath='{.status.conditions[0].status}' 2>/dev/null)
  case "$a$b" in
    TrueTrue|TrueFalse|FalseTrue|FalseFalse) break;;
  esac
  sleep 2
done
red=${red#*/}; green=${green#*/}
task_status() { k get taskrun -l "tekton.dev/pipelineRun=$1,tekton.dev/pipelineTask=$2" -o jsonpath='{.items[0].status.conditions[0].status}' 2>/dev/null; }

st=$(k get pipelinerun "$red" -o jsonpath='{.status.conditions[0].status}')
if [ "$st" != "False" ]; then
  echo "❌ a run with the failing regression suite ended with status '${st:-running}', not Failed"
  exit 1
fi
if [ "$(task_status "$red" unit-tests)" != "False" ]; then
  echo "❌ in the regression run the unit-tests Task did not fail"
  exit 1
fi
if [ -n "$(task_status "$red" deploy)" ]; then
  echo "❌ the regression run still started the deploy Task"
  exit 1
fi
echo "✅ failing suite: run Failed at unit-tests and deploy never started"

pod=$(k get taskrun -l "tekton.dev/pipelineRun=$red,tekton.dev/pipelineTask=unit-tests" -o jsonpath='{.items[0].status.podName}')
if ! k logs "$pod" -c step-report 2>/dev/null | grep -q 'archived test summary'; then
  echo "❌ the failing run did not produce the test report any more"
  exit 1
fi
echo "✅ the report step still ran in the failing run"

if [ "$(k get pipelinerun "$green" -o jsonpath='{.status.conditions[0].status}')" != "True" ]; then
  echo "❌ a run with the passing smoke suite did not Succeed"
  exit 1
fi
if [ "$(task_status "$green" deploy)" != "True" ]; then
  echo "❌ the passing run did not deploy"
  exit 1
fi
echo "✅ passing suite: run Succeeded and deploy ran"
exit 0
exit 1

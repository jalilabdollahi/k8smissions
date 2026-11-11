#!/bin/bash
NS=${NS:-k8smissions}
k() { kubectl -n "$NS" "$@"; }

if ! k get pipeline integration-test >/dev/null 2>&1; then
  echo "❌ Pipeline integration-test does not exist"
  exit 1
fi

start() {
  k create -o name -f - <<YAML
apiVersion: tekton.dev/v1
kind: PipelineRun
metadata:
  generateName: verify-it-
  labels:
    verify: finally-task
spec:
  pipelineRef:
    name: integration-test
  params:
  - name: scenario
    value: $1
YAML
}
# the check must not eat the quota itself: remove what its own runs left behind when it exits
trap 'k delete pipelinerun -l verify=finally-task --wait=false >/dev/null 2>&1
      k delete pod,service -l "run in (${bad#*/},${good#*/})" --wait=false >/dev/null 2>&1' EXIT
bad=$(start bad-fixture); good=$(start ok)
if [ -z "$bad" ] || [ -z "$good" ]; then
  echo "❌ could not start runs of integration-test (is the Service quota full?)"
  exit 1
fi
for _ in $(seq 1 30); do
  a=$(k get "$bad" -o jsonpath='{.status.conditions[0].status}' 2>/dev/null)
  b=$(k get "$good" -o jsonpath='{.status.conditions[0].status}' 2>/dev/null)
  case "$a$b" in TrueTrue|TrueFalse|FalseTrue|FalseFalse) break;; esac
  sleep 2
done
bad=${bad#*/}; good=${good#*/}

if [ "$a" != "False" ]; then
  echo "❌ the run with the bad fixture did not end Failed (status '${a:-running}', Unknown means it never finished)"
  exit 1
fi
prov=$(k get taskrun -l "tekton.dev/pipelineRun=$bad,tekton.dev/pipelineTask=provision" -o jsonpath='{.items[0].status.conditions[0].status}')
if [ "$prov" != "False" ]; then
  echo "❌ in the bad-fixture run the provision Task was expected to be the one that fails"
  exit 1
fi
echo "✅ the failing run still ends Failed at provision"
if [ "$b" != "True" ]; then
  echo "❌ the run with a good fixture did not Succeed (status: ${b:-running})"
  exit 1
fi
echo "✅ the passing run Succeeded"

left=$(k get pods,services -o name 2>/dev/null | grep -c '/scratch-')
if [ "$left" != "0" ]; then
  echo "❌ $left scratch-* Pod/Service objects are still in the namespace"
  exit 1
fi
echo "✅ no scratch-* Pod or Service is left"
exit 0
exit 1

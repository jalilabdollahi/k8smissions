#!/bin/bash
NS=${NS:-k8smissions}
k() { kubectl -n "$NS" "$@"; }
SA="system:serviceaccount:$NS:dispatcher"
can() { k auth can-i "$@" --as="$SA" 2>/dev/null; }

if ! k get pipeline orchestrate >/dev/null 2>&1 || ! k get pipeline reindex >/dev/null 2>&1 || ! k get sa dispatcher >/dev/null 2>&1; then
  echo "❌ Pipelines orchestrate, reindex or ServiceAccount dispatcher is missing"
  exit 1
fi
run=$(k create -o name -f - <<YAML
apiVersion: tekton.dev/v1
kind: PipelineRun
metadata:
  generateName: verify-orchestrate-
  labels: {verify: pipeline-rbac}
spec:
  pipelineRef:
    name: orchestrate
  taskRunTemplate:
    serviceAccountName: dispatcher
YAML
)
name=${run#*/}
trap 'k delete pipelinerun -l verify=pipeline-rbac --wait=false >/dev/null 2>&1; k delete pipelinerun "reindex-$name" --wait=false >/dev/null 2>&1' EXIT
for _ in $(seq 1 30); do
  st=$(k get "$run" -o jsonpath='{.status.conditions[0].status}' 2>/dev/null)
  [ "$st" = "True" ] || [ "$st" = "False" ] && break
  sleep 2
done
if [ "$st" != "True" ]; then
  why=$(k logs -l "tekton.dev/pipelineRun=$name" --tail=2 2>/dev/null | tr '\n' ' ')
  echo "❌ the orchestrate run did not Succeed (status '${st:-running}'): ${why:0:160}"
  exit 1
fi
child=$(k get pipelinerun "reindex-$name" -o jsonpath='{.status.conditions[0].status}' 2>/dev/null)
if [ "$child" != "True" ]; then
  echo "❌ the child run reindex-$name is missing or did not Succeed"
  exit 1
fi
echo "✅ orchestrate Succeeded and its child run reindex-$name Succeeded"

for v in create get; do
  if [ "$(can $v pipelineruns.tekton.dev)" != "yes" ]; then
    echo "❌ dispatcher cannot $v pipelineruns.tekton.dev in $NS"
    exit 1
  fi
done
echo "✅ dispatcher can create and get PipelineRuns"
for what in "delete pipelines.tekton.dev" "create pods" "get secrets" "create taskruns.tekton.dev"; do
  if [ "$(can $what)" != "no" ]; then
    echo "❌ dispatcher is allowed to $what, which this job does not need"
    exit 1
  fi
done
echo "✅ dispatcher cannot delete Pipelines, create Pods or TaskRuns, or read Secrets"
exit 0
exit 1

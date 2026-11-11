#!/bin/bash
NS=${NS:-k8smissions}
k() { kubectl -n "$NS" "$@"; }

if ! k get pipeline release >/dev/null 2>&1; then
  echo "❌ Pipeline release does not exist"
  exit 1
fi
reason=$(k get pipelinerun release-2041 -o jsonpath='{.status.conditions[0].reason}' 2>/dev/null)
if [ -z "$reason" ]; then
  echo "❌ PipelineRun release-2041 is gone; it should be cancelled, not deleted"
  exit 1
fi
if [ "$reason" != "Cancelled" ]; then
  echo "❌ release-2041 is not cancelled (reason: $reason)"
  exit 1
fi
running=$(k get pods -l tekton.dev/pipelineRun=release-2041 --field-selector=status.phase=Running -o name 2>/dev/null | grep -c .)
if [ "$running" != "0" ]; then
  echo "❌ $running pod(s) of release-2041 are still running"
  exit 1
fi
echo "✅ release-2041 is cancelled and nothing of it is running"

start() {
  k create -o name -f - <<YAML
apiVersion: tekton.dev/v1
kind: PipelineRun
metadata:
  generateName: verify-release-
  labels: {verify: approval-gate}
spec:
  pipelineRef:
    name: release
  taskRunTemplate:
    serviceAccountName: release-sa
  params:
  - {name: approval-timeout, value: "20"}
YAML
}
trap 'k delete pipelinerun -l verify=approval-gate --wait=false >/dev/null 2>&1' EXIT
silent=$(start); signed=$(start); forged=$(start)
k create configmap "approval-${signed#*/}" --from-literal=by=maria.k >/dev/null
k create configmap "approval-${forged#*/}" --from-literal=by=release-bot >/dev/null
for _ in $(seq 1 30); do
  sa=$(k get "$silent" -o jsonpath='{.status.conditions[0].status}' 2>/dev/null)
  sb=$(k get "$signed" -o jsonpath='{.status.conditions[0].status}' 2>/dev/null)
  sc=$(k get "$forged" -o jsonpath='{.status.conditions[0].status}' 2>/dev/null)
  if [ -n "$sa" ] && [ -n "$sb" ] && [ -n "$sc" ] && [ "$sa" != Unknown ] && [ "$sb" != Unknown ] && [ "$sc" != Unknown ]; then break; fi
  sleep 2
done
gate_failed() { [ "$(k get taskrun -l "tekton.dev/pipelineRun=${1#*/},tekton.dev/pipelineTask=wait-approval" -o jsonpath='{.items[0].status.conditions[0].status}' 2>/dev/null)" = "False" ]; }
if [ "$sa" != "False" ] || ! gate_failed "$silent"; then
  echo "❌ a run with no approval and approval-timeout=20 did not fail at wait-approval on its own (status '${sa:-running}')"
  exit 1
fi
echo "✅ without an approval the gate expires and the run fails"
if [ "$sb" != "True" ]; then
  echo "❌ a run approved by a listed approver did not Succeed (status '${sb:-running}')"
  exit 1
fi
echo "✅ a listed approver's sign-off lets the release through"
if [ "$sc" != "False" ] || ! gate_failed "$forged"; then
  echo "❌ a sign-off by someone who is not an approver was accepted or did not fail properly (status '${sc:-running}')"
  exit 1
fi
echo "✅ a sign-off by an unlisted person is still refused"
exit 0
exit 1

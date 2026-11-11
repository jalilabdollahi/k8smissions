#!/bin/bash
NS=${NS:-k8smissions}
k() { kubectl -n "$NS" "$@"; }

if ! k get pipeline release-notes >/dev/null 2>&1; then
  echo "❌ Pipeline release-notes does not exist"
  exit 1
fi

run=$(k create -o name -f - 2>/dev/null <<'YAML'
apiVersion: tekton.dev/v1
kind: PipelineRun
metadata:
  generateName: verify-notes-
spec:
  pipelineRef:
    name: release-notes
YAML
)
if [ -z "$run" ]; then
  echo "❌ could not start a run of Pipeline release-notes"
  exit 1
fi
trap 'k delete "$run" --wait=false >/dev/null 2>&1' EXIT

state=""
for _ in $(seq 1 30); do
  state=$(k get "$run" -o jsonpath='{.status.conditions[0].status}' 2>/dev/null)
  if [ "$state" = "True" ] || [ "$state" = "False" ]; then break; fi
  sleep 2
done
if [ "$state" != "True" ]; then
  echo "❌ a fresh run of release-notes did not succeed (status: ${state:-still running})"
  exit 1
fi
echo "✅ a fresh run of release-notes Succeeded"

name=${run#*/}
tr=$(k get taskrun -l "tekton.dev/pipelineRun=$name,tekton.dev/pipelineTask=build" -o name | head -1)
version=$(k get "$tr" -o jsonpath='{.status.results[?(@.name=="version")].value}' | tr -d '[:space:]')
if [ "$version" != "2.9.42" ]; then
  echo "❌ Task build result version is '${version}', the generate step computes something else"
  exit 1
fi
echo "✅ result version = $version"

pod=$(k get "$tr" -o jsonpath='{.status.podName}')
if ! k logs "$pod" -c step-publish 2>/dev/null | grep -q "publishing release notes for 2.9.42"; then
  echo "❌ the publish step did not print the version it publishes"
  exit 1
fi
echo "✅ the publish step used the generated version"
exit 0
exit 1

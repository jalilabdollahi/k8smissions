#!/bin/bash
NS=${NS:-k8smissions}
k() { kubectl -n "$NS" "$@"; }

for o in pipeline/inventory-build task/compile; do
  if ! k get "$o" >/dev/null 2>&1; then
    echo "❌ $o does not exist"
    exit 1
  fi
done

# a private claim for the check, so earlier runs by the player cannot warm it
k apply -f - >/dev/null <<'YAML'
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: verify-cache
spec:
  accessModes: ["ReadWriteOnce"]
  resources:
    requests:
      storage: 50Mi
YAML
cleanup() {
  k delete pipelinerun -l verify=build-cache --wait=false >/dev/null 2>&1
  k delete pvc verify-cache --wait=false >/dev/null 2>&1
}
trap cleanup EXIT

one_run() {  # prints the run name; waits until it is finished
  local run st
  run=$(k create -o name -f - <<'YAML'
apiVersion: tekton.dev/v1
kind: PipelineRun
metadata:
  generateName: verify-build-
  labels:
    verify: build-cache
spec:
  pipelineRef:
    name: inventory-build
  workspaces:
  - name: cache
    persistentVolumeClaim:
      claimName: verify-cache
YAML
  ) || return 1
  for _ in $(seq 1 25); do
    st=$(k get "$run" -o jsonpath='{.status.conditions[0].status}' 2>/dev/null)
    if [ "$st" = "True" ] || [ "$st" = "False" ]; then break; fi
    sleep 2
  done
  echo "${run#*/}"
}
hit()  { k get taskrun -l "tekton.dev/pipelineRun=$1" -o jsonpath='{.items[0].status.results[?(@.name=="cache-hit")].value}' | tr -d '[:space:]'; }
secs() {
  k get taskrun -l "tekton.dev/pipelineRun=$1" -o json | python3 -c '
import json, sys
from datetime import datetime
t = json.load(sys.stdin)["items"][0]["status"]["steps"]
s = [x for x in t if x["name"] == "resolve"][0]["terminated"]
f = lambda v: datetime.strptime(v, "%Y-%m-%dT%H:%M:%SZ")
print(int((f(s["finishedAt"]) - f(s["startedAt"])).total_seconds()))' 2>/dev/null
}

first=$(one_run)
if [ "$(k get pipelinerun "$first" -o jsonpath='{.status.conditions[0].status}')" != "True" ]; then
  echo "❌ the first run of inventory-build did not Succeed"
  exit 1
fi
second=$(one_run)
if [ "$(k get pipelinerun "$second" -o jsonpath='{.status.conditions[0].status}')" != "True" ]; then
  echo "❌ the second run of inventory-build did not Succeed"
  exit 1
fi
echo "✅ two consecutive runs with one cache volume Succeeded"

h1=$(hit "$first"); h2=$(hit "$second")
if [ "$h2" != "true" ]; then
  echo "❌ second run: cache-hit=${h2:-empty} (first run: ${h1:-empty}); the cache is not reused between runs"
  exit 1
fi
echo "✅ second run reports cache-hit=true"

t1=$(secs "$first"); t2=$(secs "$second")
if [ -z "$t1" ] || [ -z "$t2" ] || [ "$t2" -ge "$t1" ]; then
  echo "❌ resolve took ${t2:-?}s on the second run and ${t1:-?}s on the first, it should be clearly faster"
  exit 1
fi
echo "✅ resolve went from ${t1}s to ${t2}s"
exit 0
exit 1

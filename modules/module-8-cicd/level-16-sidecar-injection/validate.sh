#!/bin/bash
NS=${NS:-k8smissions}
k() { kubectl -n "$NS" "$@"; }

if ! k get pipeline integration-db-test >/dev/null 2>&1 || ! k get task db-test >/dev/null 2>&1; then
  echo "❌ Pipeline integration-db-test or Task db-test is missing"
  exit 1
fi
if [ -z "$(k get task db-test -o jsonpath='{.spec.sidecars[0].name}')" ]; then
  echo "❌ Task db-test no longer has its mock-db sidecar"
  exit 1
fi
start() { # startup port
  k create -o name -f - <<YAML
apiVersion: tekton.dev/v1
kind: PipelineRun
metadata:
  generateName: verify-db-
  labels: {verify: sidecar-race}
spec:
  pipelineRef:
    name: integration-db-test
  params:
  - {name: db-startup, value: "$1"}
  - {name: db-port, value: "$2"}
YAML
}
trap 'k delete pipelinerun -l verify=sidecar-race --wait=false >/dev/null 2>&1' EXIT
fast=$(start 4 8080); slow=$(start 8 8080); crawl=$(start 12 8080); dead=$(start 1 9)
for _ in $(seq 1 40); do
  pending=0
  for r in $fast $slow $crawl; do
    s=$(k get "$r" -o jsonpath='{.status.conditions[0].status}' 2>/dev/null)
    [ "$s" = "True" ] || [ "$s" = "False" ] || pending=1
  done
  [ "$pending" = 0 ] && break
  sleep 2
done
rows() { k get taskrun -l "tekton.dev/pipelineRun=${1#*/}" -o jsonpath='{.items[0].status.results[?(@.name=="rows")].value}' 2>/dev/null; }
bad=0
for pair in "4s:$fast" "8s:$slow" "12s:$crawl"; do
  s=$(k get "${pair#*:}" -o jsonpath='{.status.conditions[0].status}' 2>/dev/null)
  if [ "$s" = "True" ] && [ "$(rows "${pair#*:}")" = "3" ]; then
    echo "✅ database ready after ${pair%%:*}: Succeeded with rows=3"
  else
    echo "❌ database ready after ${pair%%:*}: status '${s:-running}', rows '$(rows "${pair#*:}")'"
    bad=1
  fi
done
[ "$bad" = 0 ] || exit 1
for _ in $(seq 1 20); do
  s=$(k get "$dead" -o jsonpath='{.status.conditions[0].status}' 2>/dev/null)
  [ "$s" = "True" ] || [ "$s" = "False" ] && break
  sleep 2
done
if [ "$s" != "False" ]; then
  echo "❌ with an unreachable database the run did not end Failed in time (status '${s:-still running}')"
  exit 1
fi
echo "✅ an unreachable database fails the run instead of hanging it"
exit 0
exit 1

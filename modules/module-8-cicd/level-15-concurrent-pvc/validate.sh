#!/bin/bash
NS=${NS:-k8smissions}
k() { kubectl -n "$NS" "$@"; }

if ! k get pipeline build-shop >/dev/null 2>&1; then
  echo "❌ Pipeline build-shop does not exist"
  exit 1
fi
phase=$(k get pvc build-scratch -o jsonpath='{.status.phase}' 2>/dev/null)
if [ -z "$phase" ]; then
  echo "❌ PVC build-scratch is gone: the platform binds its runs to it by name"
  exit 1
fi
start() {
  k create -o name -f - <<YAML
apiVersion: tekton.dev/v1
kind: PipelineRun
metadata:
  generateName: verify-shop-
  labels: {verify: concurrent-pvc}
spec:
  pipelineRef:
    name: build-shop
  workspaces:
  - name: scratch
    persistentVolumeClaim:
      claimName: build-scratch
YAML
}
trap 'k delete pipelinerun -l verify=concurrent-pvc --wait=false >/dev/null 2>&1' EXIT
runs="$(start) $(start) $(start)"
for _ in $(seq 1 35); do
  pending=0
  for r in $runs; do
    s=$(k get "$r" -o jsonpath='{.status.conditions[0].status}' 2>/dev/null)
    [ "$s" = "True" ] || [ "$s" = "False" ] || pending=1
  done
  [ "$pending" = 0 ] && break
  sleep 2
done
ok=0; seen=""
for r in $runs; do
  n=${r#*/}
  s=$(k get "$r" -o jsonpath='{.status.conditions[0].status}' 2>/dev/null)
  sum=$(k get taskrun -l "tekton.dev/pipelineRun=$n,tekton.dev/pipelineTask=verify" -o jsonpath='{.items[0].status.results[?(@.name=="checksum")].value}' 2>/dev/null)
  want=$(printf 'artifact for %s' "$n" | sha256sum | cut -d' ' -f1)
  if [ "$s" = "True" ] && [ "$sum" = "$want" ]; then
    ok=$((ok + 1)); seen="$seen $sum"
  else
    [ "$s" = "True" ] || [ "$s" = "False" ] || echo "   $n: $(k get "$r" -o jsonpath='{.status.conditions[0].reason}: {.status.conditions[0].message}' 2>/dev/null | cut -c1-200); pods: $(k get pods -l tekton.dev/pipelineRun=$n --no-headers 2>/dev/null | awk '{print $1":"$3}' | tr '\n' ' ')"
    echo "❌ $n: status '${s:-running}', checksum '${sum:-none}' (its own artifact hashes to ${want:0:12}...)"
  fi
done
if [ "$ok" != "3" ]; then
  echo "❌ only $ok of 3 concurrent runs built and verified their own artifact"
  exit 1
fi
if [ "$(echo $seen | tr ' ' '\n' | sort -u | grep -c .)" != "3" ]; then
  echo "❌ the three runs did not report distinct checksums"
  exit 1
fi
echo "✅ three concurrent runs on build-scratch all Succeeded with their own, distinct checksums"
exit 0
exit 1

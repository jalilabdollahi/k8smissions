# Helpers for module 12 validate.sh/setup.sh:  . ../_fixtures/lib.sh   (cwd = level directory)
# Needs kubectl (and jq for a few helpers). $NS defaults to k8smissions.
NS="${NS:-k8smissions}"

ok()  { echo "✅ $*"; }
bad() { echo "❌ $*"; }

# ensure_probe: a curl pod named `probe` in $NS (labels: app=probe only, so it is "an outsider").
ensure_probe() {
  kubectl get pod probe -n "$NS" >/dev/null 2>&1 || \
    kubectl run probe -n "$NS" --image=curlimages/curl:8.10.1 --restart=Never --labels=app=probe \
      --command -- sleep 3600 >/dev/null 2>&1
  kubectl wait pod/probe -n "$NS" --for=condition=Ready --timeout=60s >/dev/null 2>&1
}

# pcurl <curl args>: curl from the probe pod, silent, 5s limit.
pcurl() { kubectl exec -n "$NS" probe -- curl -s --max-time 5 "$@" 2>/dev/null; }

# live_pods <selector>: names of Running, non-terminating pods.
live_pods() {
  kubectl get pods -n "$NS" -l "$1" -o json 2>/dev/null | \
    jq -r '.items[] | select(.metadata.deletionTimestamp==null and .status.phase=="Running") | .metadata.name'
}

# ready_count <selector>: Ready, non-terminating pods.
ready_count() {
  kubectl get pods -n "$NS" -l "$1" -o json 2>/dev/null | \
    jq '[.items[] | select(.metadata.deletionTimestamp==null) | select(any(.status.conditions[]?; .type=="Ready" and .status=="True"))] | length'
}

# restart_sum <selector>: total container restarts of the matching pods.
restart_sum() {
  kubectl get pods -n "$NS" -l "$1" -o json 2>/dev/null | \
    jq '[.items[].status.containerStatuses[]?.restartCount] | add // 0'
}

# rollout_done <deploy> <replicas>: true when the Deployment has finished rolling out exactly <replicas> pods.
rollout_done() {
  local want="$2" st a b c d g o
  st=$(kubectl get deploy "$1" -n "$NS" -o jsonpath='{.spec.replicas}/{.status.replicas}/{.status.updatedReplicas}/{.status.readyReplicas}/{.metadata.generation}/{.status.observedGeneration}' 2>/dev/null)
  IFS=/ read -r a b c d g o <<<"$st"
  [ "$a" = "$want" ] && [ "${b:-0}" = "$want" ] && [ "${c:-0}" = "$want" ] && [ "${d:-0}" = "$want" ] && [ "$g" = "$o" ]
}

# wait_rollout <deploy> [secs]: wait (setup helper) until the Deployment is fully available.
wait_rollout() { kubectl rollout status "deploy/$1" -n "$NS" --timeout="${2:-120}s" >/dev/null; }

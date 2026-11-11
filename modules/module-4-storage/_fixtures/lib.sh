# Helpers sourced by validate.sh scripts of module 4:  . ../_fixtures/lib.sh
# Needs $NS (set by the game and by test_levels.py).
NS="${NS:-k8smissions}"

ok()  { echo "✅ $*"; }
bad() { echo "❌ $*"; }

# Start (once) a curl pod in the namespace to call Services from inside the cluster.
ensure_probe() {
  kubectl get pod probe -n "$NS" >/dev/null 2>&1 || \
    kubectl run probe -n "$NS" --image=curlimages/curl:8.10.1 --restart=Never \
      --command -- sleep 3600 >/dev/null 2>&1
  kubectl wait pod/probe -n "$NS" --for=condition=Ready --timeout=60s >/dev/null 2>&1
}

# pcurl <curl args>: run curl from the probe pod, quiet, 5s limit.
pcurl() { kubectl exec -n "$NS" probe -- curl -s --max-time 5 "$@" 2>/dev/null; }

# wait_replacement <label-selector> <old-pod> [seconds]: prints the name of a Ready
# pod matching the selector that is not <old-pod>; returns 1 on timeout.
wait_replacement() {
  local sel="$1" old="$2" end=$((SECONDS + ${3:-60})) name
  while [ $SECONDS -lt $end ]; do
    name=$(kubectl get pods -n "$NS" -l "$sel" --field-selector=status.phase=Running \
      -o jsonpath='{range .items[?(@.status.containerStatuses[0].ready==true)]}{.metadata.name}{"\n"}{end}' 2>/dev/null \
      | grep -vx "$old" | head -1)
    if [ -n "$name" ]; then echo "$name"; return 0; fi
    sleep 2
  done
  return 1
}

# Helpers for module 11 validators and setup scripts:  . ../_fixtures/lib.sh
# Needs $NS (set by the game and by test_levels.py), kubectl and jq.
NS="${NS:-k8smissions}"
FIX="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

ok()  { echo "✅ $*"; }
bad() { echo "❌ $*"; }

# cpu quantity (4, 250m) -> millicores
cpu_to_m() { awk -v q="$1" 'BEGIN{ if (q ~ /m$/) { sub(/m$/,"",q); print int(q) } else print int(q*1000) }'; }
# memory quantity (900Mi, 1Gi, 123456Ki, bytes) -> Mi
mem_to_mi() {
  awk -v q="$1" 'BEGIN{
    if (q ~ /Ki$/) { sub(/Ki$/,"",q); print int(q/1024) }
    else if (q ~ /Mi$/) { sub(/Mi$/,"",q); print int(q) }
    else if (q ~ /Gi$/) { sub(/Gi$/,"",q); print int(q*1024) }
    else print int(q/1048576) }'
}

# ready_count <selector>: number of Ready, non-terminating pods
ready_count() {
  kubectl -n "$NS" get pods -l "$1" -o json 2>/dev/null | jq '[.items[]
    | select(.metadata.deletionTimestamp==null)
    | select(any(.status.conditions[]?; .type=="Ready" and .status=="True"))] | length'
}
# wait_ready <selector> <count> [timeout_s]: succeed when at least <count> pods are Ready
wait_ready() {
  local end=$((SECONDS + ${3:-60})) n
  while [ $SECONDS -lt $end ]; do
    n=$(ready_count "$1"); [ "${n:-0}" -ge "$2" ] && return 0
    sleep 2
  done
  return 1
}

# restart_sum <selector>: total restartCount of the matching pods
restart_sum() {
  kubectl -n "$NS" get pods -l "$1" -o json 2>/dev/null |
    jq '[.items[].status.containerStatuses[]?.restartCount] | add // 0'
}

# cgroup_cpu <pod> [container]: prints "nr_periods nr_throttled throttled_usec" read from cgroup v2 cpu.stat.
# Prints "0 0 0" when the container has no CPU limit (the kernel then reports no bandwidth counters).
cgroup_cpu() {
  local c=(); [ -n "${2:-}" ] && c=(-c "$2")
  kubectl exec -n "$NS" "${c[@]}" "$1" -- cat /sys/fs/cgroup/cpu.stat 2>/dev/null |
    awk '$1=="nr_periods"{p=$2} $1=="nr_throttled"{t=$2} $1=="throttled_usec"{u=$2} END{print p+0, t+0, u+0}'
}

# cgroup_mem_mi <pod> [container]: current memory of the container's cgroup, in Mi
cgroup_mem_mi() {
  local c=(); [ -n "${2:-}" ] && c=(-c "$2")
  kubectl exec -n "$NS" "${c[@]}" "$1" -- cat /sys/fs/cgroup/memory.current 2>/dev/null |
    awk '{print int($1/1048576)}'
}

# run_probe <url> <rate> <conc> <duration_s> [KEY=VAL ...]
# Runs fixtures/probe.py in a throwaway pod, waits for it to finish and prints the final
# JSON line (see probe.py) on stdout. Extra KEY=VAL pairs become environment variables
# (TIMEOUT=10 RETRY=1 ...). Prints nothing when the probe could not run.
run_probe() {
  local url=$1 rate=$2 conc=$3 dur=$4; shift 4
  local name="vprobe-$$-$RANDOM" extra="" kv
  for kv in "$@"; do extra+=$',\n      {"name": "'"${kv%%=*}"'", "value": "'"${kv#*=}"'"}'; done
  kubectl -n "$NS" create configmap probe-script --from-file=probe.py="$FIX/probe.py" \
    --dry-run=client -o yaml | kubectl apply -n "$NS" -f - >/dev/null 2>&1
  kubectl apply -n "$NS" -f - >/dev/null 2>&1 <<YAML
{"apiVersion":"v1","kind":"Pod","metadata":{"name":"$name","labels":{"app":"vprobe"}},
 "spec":{"restartPolicy":"Never","terminationGracePeriodSeconds":1,
  "containers":[{"name":"probe","image":"python:3.12-alpine","command":["python","-u","/probe/probe.py"],
   "env":[{"name":"URL","value":"$url"},{"name":"RATE","value":"$rate"},{"name":"CONC","value":"$conc"},
          {"name":"DURATION","value":"$dur"},{"name":"WINDOW","value":"5"}$extra],
   "resources":{"requests":{"cpu":"10m","memory":"16Mi"},"limits":{"memory":"96Mi"}},
   "volumeMounts":[{"name":"s","mountPath":"/probe"}]}],
  "volumes":[{"name":"s","configMap":{"name":"probe-script"}}]}}
YAML
  local end=$((SECONDS + dur + 40)) ph
  while [ $SECONDS -lt $end ]; do
    ph=$(kubectl -n "$NS" get pod "$name" -o jsonpath='{.status.phase}' 2>/dev/null)
    [ "$ph" = Succeeded ] || [ "$ph" = Failed ] && break
    sleep 1
  done
  kubectl -n "$NS" logs "$name" 2>/dev/null | grep '"final"' | tail -1
  kubectl -n "$NS" delete pod "$name" --wait=false >/dev/null 2>&1
}

# start_load <pod-name> <url> <rate> <conc> [KEY=VAL ...]
# Starts (once) a long-running probe pod that keeps sending traffic (DURATION=0, log line every 5s).
# Does nothing if a pod with that name already exists.
start_load() {
  local name=$1 url=$2 rate=$3 conc=$4; shift 4
  kubectl -n "$NS" get pod "$name" >/dev/null 2>&1 && return 0
  local extra="" kv
  for kv in "$@"; do extra+=$',\n      {"name": "'"${kv%%=*}"'", "value": "'"${kv#*=}"'"}'; done
  kubectl -n "$NS" create configmap probe-script --from-file=probe.py="$FIX/probe.py" \
    --dry-run=client -o yaml | kubectl apply -n "$NS" -f - >/dev/null 2>&1
  kubectl apply -n "$NS" -f - >/dev/null 2>&1 <<YAML
{"apiVersion":"v1","kind":"Pod","metadata":{"name":"$name","labels":{"app":"$name"}},
 "spec":{"restartPolicy":"Always","terminationGracePeriodSeconds":1,
  "containers":[{"name":"probe","image":"python:3.12-alpine","command":["python","-u","/probe/probe.py"],
   "env":[{"name":"URL","value":"$url"},{"name":"RATE","value":"$rate"},{"name":"CONC","value":"$conc"},
          {"name":"DURATION","value":"0"},{"name":"WINDOW","value":"5"}$extra],
   "resources":{"requests":{"cpu":"10m","memory":"16Mi"},"limits":{"memory":"96Mi"}},
   "volumeMounts":[{"name":"s","mountPath":"/probe"}]}],
  "volumes":[{"name":"s","configMap":{"name":"probe-script"}}]}}
YAML
}

# live_pods <selector>: names of Running, non-terminating pods, one per line
live_pods() {
  kubectl -n "$NS" get pods -l "$1" -o json 2>/dev/null |
    jq -r '.items[] | select(.metadata.deletionTimestamp==null and .status.phase=="Running") | .metadata.name'
}

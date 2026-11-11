#!/bin/bash
# Shared helpers for module 9. Source from setup.sh / validate.sh:  . ../_fixtures/lib.sh
# Never hard-code node names; the cluster's node names differ.

NS=${NS:-k8smissions}

# worker node names, one per line, sorted (control plane excluded)
workers() {
  kubectl get nodes -l '!node-role.kubernetes.io/control-plane' \
    -o jsonpath='{range .items[*]}{.metadata.name}{"\n"}{end}' | sort
}
# worker_n 1 -> first worker, worker_n 2 -> second worker
worker_n() { workers | sed -n "${1}p"; }

# cpu quantity (4, 250m) -> millicores
cpu_to_m() { awk -v q="$1" 'BEGIN{ if (q ~ /m$/) { sub(/m$/,"",q); print int(q) } else print int(q*1000) }'; }
# memory quantity (900Mi, 1Gi, 8123872Ki, 1500000000) -> Mi
mem_to_mi() {
  awk -v q="$1" 'BEGIN{
    if (q ~ /Ki$/) { sub(/Ki$/,"",q); print int(q/1024) }
    else if (q ~ /Mi$/) { sub(/Mi$/,"",q); print int(q) }
    else if (q ~ /Gi$/) { sub(/Gi$/,"",q); print int(q*1024) }
    else if (q ~ /M$/) { sub(/M$/,"",q); print int(q*1000000/1048576) }
    else if (q ~ /G$/) { sub(/G$/,"",q); print int(q*1000000000/1048576) }
    else print int(q/1048576) }'
}

# free_cpu_m <node>: allocatable CPU minus the requests the scheduler has already counted (millicores)
free_cpu_m() {
  local alloc req
  alloc=$(kubectl get node "$1" -o jsonpath='{.status.allocatable.cpu}')
  req=$(kubectl describe node "$1" | awk '/^Allocated resources:/{f=1} f && $1=="cpu"{print $2; exit}')
  echo $(( $(cpu_to_m "$alloc") - $(cpu_to_m "${req:-0}") ))
}
# free_mem_mi <node>: same for memory (Mi)
free_mem_mi() {
  local alloc req
  alloc=$(kubectl get node "$1" -o jsonpath='{.status.allocatable.memory}')
  req=$(kubectl describe node "$1" | awk '/^Allocated resources:/{f=1} f && $1=="memory"{print $2; exit}')
  echo $(( $(mem_to_mi "$alloc") - $(mem_to_mi "${req:-0}") ))
}

# wait_pods_ready <selector> <count> [timeout_s]: succeed when count pods matching selector are Ready
wait_pods_ready() {
  local sel=$1 want=$2 t=${3:-120} i=0 n
  while [ $i -lt "$t" ]; do
    n=$(kubectl -n "$NS" get pods -l "$sel" -o json 2>/dev/null |
      jq '[.items[] | select(.metadata.deletionTimestamp==null) | select(any(.status.conditions[]?; .type=="Ready" and .status=="True"))] | length')
    [ "${n:-0}" -ge "$want" ] && return 0
    sleep 2; i=$((i+2))
  done
  return 1
}

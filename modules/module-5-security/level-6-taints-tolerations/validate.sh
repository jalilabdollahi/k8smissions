#!/bin/bash
NS=${NS:-k8smissions}
k() { kubectl -n "$NS" "$@"; }

pool=$(kubectl get nodes -l pool=etl -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)
if [ -z "$pool" ]; then
  echo "❌ no node carries the label pool=etl"
  exit 1
fi

# the fence must stay: both taints, effect NoSchedule
taints=$(kubectl get node "$pool" -o jsonpath='{range .spec.taints[*]}{.key}={.value}:{.effect}{" "}{end}')
for t in dedicated=etl:NoSchedule team=data:NoSchedule; do
  if ! echo " $taints " | grep -q " $t "; then
    echo "❌ the pool node lost its taint $t"
    exit 1
  fi
done
echo "✅ the pool node keeps both of its taints"

# no blanket tolerations
if k get deploy etl-runner -o jsonpath='{range .spec.template.spec.tolerations[*]}{.key}{"|"}{.operator}{"\n"}{end}' | grep -q -e '^|Exists$' -e '^|$'; then
  echo "❌ etl-runner tolerates every taint; tolerate only the two that fence the pool"
  exit 1
fi

if [ "$(k get deploy etl-runner -o jsonpath='{.spec.replicas}' 2>/dev/null)" != "2" ] || \
   [ "$(k get deploy web-frontend -o jsonpath='{.spec.replicas}' 2>/dev/null)" != "2" ]; then
  echo "❌ etl-runner and web-frontend must keep 2 replicas each"
  exit 1
fi
if ! k rollout status deploy/etl-runner --timeout=40s >/dev/null 2>&1; then
  echo "❌ etl-runner: $(k get deploy etl-runner -o jsonpath='{.status.readyReplicas}')/2 pods Ready"
  exit 1
fi
on_pool=$(k get pods -l app=etl-runner --field-selector=status.phase=Running -o jsonpath='{range .items[*]}{.spec.nodeName}{"\n"}{end}' | grep -c "^$pool\$")
if [ "$on_pool" -ne 2 ]; then
  echo "❌ only $on_pool of 2 etl-runner pods run on the pool node"
  exit 1
fi
echo "✅ both etl-runner pods run on the pool node"

if ! k rollout status deploy/web-frontend --timeout=30s >/dev/null 2>&1; then
  echo "❌ web-frontend is not fully rolled out"
  exit 1
fi
if k get pods -l app=web-frontend -o jsonpath='{range .items[*]}{.spec.nodeName}{"\n"}{end}' | grep -q "^$pool\$"; then
  echo "❌ a web-frontend pod runs on the pool node"
  exit 1
fi

# the fence still works for newcomers: a pod pinned to the pool without tolerations must stay Pending
k delete pod fence-check --ignore-not-found --wait=true >/dev/null 2>&1
k apply -f - >/dev/null <<EOP
apiVersion: v1
kind: Pod
metadata:
  name: fence-check
spec:
  terminationGracePeriodSeconds: 0
  nodeSelector: {pool: etl}
  containers:
  - name: c
    image: registry.k8s.io/pause:3.9
EOP
sleep 6
sched=$(k get pod fence-check -o jsonpath='{.status.conditions[?(@.type=="PodScheduled")].status}')
k delete pod fence-check --wait=false >/dev/null 2>&1
if [ "$sched" = "True" ]; then
  echo "❌ an untolerating pod was scheduled onto the pool: the fence is gone"
  exit 1
fi
echo "✅ web-frontend stays off the pool and untolerating pods are still refused"
exit 0
exit 1

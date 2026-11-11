#!/bin/bash
NS=${NS:-k8smissions}
k() { kubectl -n "$NS" "$@"; }
SA="system:serviceaccount:$NS:log-shipper"
can() { kubectl auth can-i "$@" --as="$SA" 2>/dev/null; }

# 1. the shipper really runs as its own ServiceAccount
sa=$(k get deploy log-shipper -o jsonpath='{.spec.template.spec.serviceAccountName}' 2>/dev/null)
if [ "$sa" != "log-shipper" ]; then
  echo "❌ Deployment log-shipper must run as ServiceAccount log-shipper (found: ${sa:-none})"
  exit 1
fi

# 2. what must be allowed
for want in "get pods" "list pods" "get pods/log"; do
  if [ "$(can $want -n "$NS")" != "yes" ]; then
    echo "❌ $SA cannot $want in $NS"
    exit 1
  fi
done
echo "✅ log-shipper can read pods and their logs"

# 3. what must stay forbidden
for no in "delete pods" "create pods" "get secrets" "list configmaps" "create pods/exec"; do
  if [ "$(can $no -n "$NS")" = "yes" ]; then
    echo "❌ log-shipper is too powerful: it can $no"
    exit 1
  fi
done
for no in "get pods -n kube-system" "get pods/log -n kube-system" "get secrets -n kube-system"; do
  if [ "$(can $no)" = "yes" ]; then
    echo "❌ log-shipper has access outside this namespace: it can $no"
    exit 1
  fi
done
echo "✅ log-shipper still cannot touch secrets, configmaps, exec or other namespaces"

# 4. the workload is healthy and actually shipping
if ! k wait --for=condition=Available deploy/log-shipper --timeout=40s >/dev/null 2>&1; then
  echo "❌ log-shipper is not Available"
  exit 1
fi
pod=$(k get pods -l app=log-shipper -o jsonpath='{.items[0].metadata.name}')
r1=$(k get pod "$pod" -o jsonpath='{.status.containerStatuses[0].restartCount}')
a=$(k exec "$pod" -- cat /data/orders.log 2>/dev/null | tail -1)
sleep 14
b=$(k exec "$pod" -- cat /data/orders.log 2>/dev/null | tail -1)
r2=$(k get pod "$pod" -o jsonpath='{.status.containerStatuses[0].restartCount}')
if [ "$r1" != "$r2" ] || [ "$(k get pod "$pod" -o jsonpath='{.status.phase}')" != "Running" ]; then
  echo "❌ log-shipper keeps restarting"
  exit 1
fi
case "$a" in order-*) ;; *) echo "❌ output file has no lines from orders yet"; exit 1;; esac
if [ "$a" = "$b" ]; then
  echo "❌ output file is not being updated"
  exit 1
fi
echo "✅ log-shipper is Running and the file keeps getting new lines from orders ($b)"
exit 0
exit 1

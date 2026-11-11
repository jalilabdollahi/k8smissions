#!/bin/bash
# The "hardening" change dedicated the worker pool: it labelled the workers and tainted them for batch work.
for n in $(kubectl get nodes -l '!node-role.kubernetes.io/control-plane' -o jsonpath='{.items[*].metadata.name}'); do
  kubectl label node "$n" pool=general --overwrite >/dev/null
  kubectl taint node "$n" dedicated=batch:NoSchedule --overwrite >/dev/null
done
kubectl -n kube-system wait --for=condition=Available deployment/metrics-server --timeout=120s

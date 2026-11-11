#!/bin/bash
NS=k8smissions
node=$(kubectl get nodes -l maintenance=pending -o jsonpath='{.items[0].metadata.name}')
# 3 of 2 replicas can never be satisfied: allow one pod down at a time
kubectl -n $NS patch pdb checkout-pdb --type=merge -p '{"spec":{"minAvailable":1}}'
# the other worker still carries the experiment's taint
for n in $(kubectl get nodes -o jsonpath='{.items[?(@.spec.taints)].metadata.name}'); do
  kubectl taint node "$n" dedicated- 2>/dev/null
done
kubectl drain "$node" --ignore-daemonsets --delete-emptydir-data --force --timeout=150s
kubectl -n $NS rollout status deploy/checkout --timeout=60s
kubectl -n $NS rollout status deploy/search --timeout=60s

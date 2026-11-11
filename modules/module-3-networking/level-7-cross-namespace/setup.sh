#!/bin/bash
# the second team's namespaces are created imperatively, so label them for cleanup
for ns in warehouse contractors; do
  kubectl create namespace "$ns"
  kubectl label namespace "$ns" k8smissions/managed=true --overwrite
done
kubectl -n "$NS" apply -f ../_fixtures/probe.yaml
../_fixtures/wait-ready.sh probe

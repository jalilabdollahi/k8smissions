#!/bin/bash
# Two workers with different disks. Node labels outside kubernetes.io are reset between levels.
set -- $(kubectl get nodes -l '!node-role.kubernetes.io/control-plane' -o name)
if [ "$#" -lt 2 ]; then
  echo "need two worker nodes" >&2
  exit 1
fi
kubectl label "$1" disk=ssd --overwrite
kubectl label "$2" disk=hdd --overwrite
kubectl -n "$NS" apply -f ../_fixtures/probe.yaml
../_fixtures/wait-ready.sh probe

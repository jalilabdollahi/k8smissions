#!/bin/bash
# Make the first worker the dedicated ETL pool (node state is reset between levels).
node=$(kubectl get nodes -l '!node-role.kubernetes.io/control-plane' -o jsonpath='{.items[0].metadata.name}')
kubectl label node "$node" pool=etl --overwrite
kubectl taint node "$node" dedicated=etl:NoSchedule team=data:NoSchedule --overwrite

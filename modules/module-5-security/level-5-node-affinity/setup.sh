#!/bin/bash
# Label exactly one worker as the restricted-data node (node state is reset between levels).
node=$(kubectl get nodes -l '!node-role.kubernetes.io/control-plane' -o jsonpath='{.items[0].metadata.name}')
kubectl label node "$node" data-class=restricted --overwrite

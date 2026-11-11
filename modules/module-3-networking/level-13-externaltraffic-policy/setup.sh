#!/bin/bash
# gw-client: a host-network curl pod on the control-plane node. Calls from it to a
# worker's address arrive with that node's IP as source, like an outside client.
cat <<'YAML' | kubectl -n "$NS" apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: gw-client
spec:
  hostNetwork: true
  nodeSelector:
    node-role.kubernetes.io/control-plane: ""
  tolerations:
  - key: node-role.kubernetes.io/control-plane
    operator: Exists
    effect: NoSchedule
  terminationGracePeriodSeconds: 0
  containers:
  - name: curl
    image: curlimages/curl:8.10.1
    command: ["sleep", "86400"]
YAML
../_fixtures/wait-ready.sh gw-client

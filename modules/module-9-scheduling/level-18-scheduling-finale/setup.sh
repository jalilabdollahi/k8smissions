#!/bin/bash
# Only the first worker carries a zone label; a leftover debug pod holds hostPort 8125 on the second.
. ../_fixtures/lib.sh
a=$(worker_n 1); b=$(worker_n 2)
kubectl label node "$a" zone=zone-a --overwrite || exit 1
kubectl -n "$NS" apply -f - <<YAML
apiVersion: v1
kind: Pod
metadata:
  name: statsd-debug
  namespace: k8smissions
  annotations:
    owner: sre-oncall
    note: "temporary packet capture on the statsd port, opened during last month's incident"
spec:
  nodeName: $b
  containers:
  - name: capture
    image: busybox:1.37
    command: ["sh", "-c", "mkdir -p /tmp/w; exec httpd -f -p 8125 -h /tmp/w"]
    ports:
    - {containerPort: 8125, hostPort: 8125}
    resources:
      requests: {cpu: 10m, memory: 16Mi}
YAML
sleep 3

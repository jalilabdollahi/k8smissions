#!/bin/bash
# fourteen scratch environments left behind by failed integration-test runs (it-0701 .. it-0714)
f=$(mktemp)
for n in $(seq 701 714); do
  cat >> "$f" <<YAML
apiVersion: v1
kind: Pod
metadata:
  name: scratch-it-0$n
  labels: {app: scratch, run: it-0$n}
spec:
  terminationGracePeriodSeconds: 1
  containers:
  - name: db
    image: registry.k8s.io/pause:3.9
---
apiVersion: v1
kind: Service
metadata:
  name: scratch-it-0$n
  labels: {app: scratch, run: it-0$n}
spec:
  selector: {run: it-0$n}
  ports:
  - port: 5678
---
YAML
done
kubectl -n "$NS" apply -f "$f" >/dev/null
rm -f "$f"

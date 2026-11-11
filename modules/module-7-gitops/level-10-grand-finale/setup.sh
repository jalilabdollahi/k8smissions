#!/bin/bash
# the namespace quota is part of the tenant contract; the repo only has a main branch (release-2.3 was deleted)
kubectl -n "$NS" apply -f ../_fixtures/probe.yaml
kubectl -n "$NS" apply -f - <<'YAML'
apiVersion: v1
kind: ResourceQuota
metadata:
  name: tenant-compute
  labels: {k8smissions/managed: "true"}
spec:
  hard:
    requests.cpu: 300m
    requests.memory: 256Mi
YAML
../_fixtures/gitserver/seed.sh finale repo "grand-finale chart 2.3.0"
../_fixtures/argo-app.sh app.yaml
../_fixtures/wait-ready.sh probe

#!/bin/bash
# release 1: the old production install; release 2: today's upgrade from the values file in the repository
kubectl -n "$NS" apply -f ../_fixtures/probe.yaml
../_fixtures/gitserver/seed.sh search repo "search chart 1.8.0 and production values"
helm -n "$NS" install search repo/chart --set replicaCount=2 --set message="search prod: ranking v0.2.3" --wait --timeout 90s >/dev/null
helm -n "$NS" upgrade search repo/chart -f repo/values-prod.yaml >/dev/null
../_fixtures/wait-ready.sh probe

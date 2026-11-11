#!/bin/bash
# Compliance replays customer traffic from inside the cluster with this pod.
kubectl -n "$NS" apply -f ../_fixtures/probe.yaml
kubectl -n "$NS" annotate pod probe audit-traffic="replays requests against Service checkout" --overwrite
../_fixtures/wait-ready.sh probe

#!/bin/bash
# debug client shared by module 3
kubectl -n "$NS" apply -f ../_fixtures/probe.yaml
../_fixtures/wait-ready.sh probe
echo "probe ready: it can reach any worker node address from inside the cluster"

#!/bin/bash
# debug client shared by module 3
kubectl -n "$NS" apply -f ../_fixtures/probe.yaml
../_fixtures/wait-ready.sh probe
echo "probe ready: use it as the healthy reference for how names resolve here"

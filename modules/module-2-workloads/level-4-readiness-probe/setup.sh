#!/bin/bash
# Curl client the validator uses to hammer the catalog Service while a pod is replaced.
kubectl -n "$NS" apply -f ../_fixtures/probe.yaml
../_fixtures/wait-ready.sh probe
echo "client ready: catalog warm-up scenario follows"

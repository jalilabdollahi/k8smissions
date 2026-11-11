#!/bin/bash
# Curl client that polls critical-api during the validator's own release.
kubectl -n "$NS" apply -f ../_fixtures/probe.yaml
../_fixtures/wait-ready.sh probe
echo "client ready: critical-api release scenario follows"

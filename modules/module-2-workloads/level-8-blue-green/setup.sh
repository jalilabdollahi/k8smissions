#!/bin/bash
# Curl client that samples the shop Service to tell blue from green.
kubectl -n "$NS" apply -f ../_fixtures/probe.yaml
../_fixtures/wait-ready.sh probe
echo "client ready: blue and green versions follow"

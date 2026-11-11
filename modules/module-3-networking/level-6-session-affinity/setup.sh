#!/bin/bash
# two clients with different source addresses
kubectl -n "$NS" apply -f ../_fixtures/probe.yaml -f ../_fixtures/probe-b.yaml
../_fixtures/wait-ready.sh probe probe-b
echo "both clients ready for cookie tests"

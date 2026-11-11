#!/bin/bash
# debug client shared by module 3
kubectl -n "$NS" apply -f ../_fixtures/probe.yaml
../_fixtures/wait-ready.sh probe
echo "probe ready: compare what the cart Service sends traffic to with what you expect"

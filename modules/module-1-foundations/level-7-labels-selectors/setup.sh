#!/bin/bash
kubectl -n "$NS" apply -f ../_fixtures/probe.yaml
../_fixtures/wait-ready.sh probe
kubectl -n "$NS" annotate pod probe note="traffic is tested through service blog" --overwrite

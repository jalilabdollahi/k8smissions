#!/bin/bash
kubectl -n "$NS" apply -f ../_fixtures/probe.yaml >/dev/null
kubectl -n "$NS" get pod probe -o name
../_fixtures/wait-ready.sh probe

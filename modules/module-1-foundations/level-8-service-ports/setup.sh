#!/bin/bash
kubectl -n "$NS" apply -f ../_fixtures/probe.yaml
kubectl -n "$NS" label pod probe role=client --overwrite
../_fixtures/wait-ready.sh probe

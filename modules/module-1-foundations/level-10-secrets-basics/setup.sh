#!/bin/bash
kubectl -n "$NS" apply -f ../_fixtures/probe.yaml
kubectl -n "$NS" annotate pod probe owner=reports-team --overwrite
../_fixtures/wait-ready.sh probe

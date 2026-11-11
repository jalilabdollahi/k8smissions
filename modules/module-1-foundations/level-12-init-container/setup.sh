#!/bin/bash
# Month-end reporting checks the ledger page from this pod, outside the ledger workloads.
kubectl -n "$NS" apply -f ../_fixtures/probe.yaml
kubectl -n "$NS" annotate pod probe ledger-checks="queries Service ledger-web, never ledger-db directly" --overwrite
../_fixtures/wait-ready.sh probe

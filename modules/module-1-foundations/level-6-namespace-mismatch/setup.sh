#!/bin/bash
kubectl -n "$NS" apply -f ../_fixtures/probe.yaml
kubectl -n "$NS" create configmap deploy-log --from-literal=2024-06-03="alice applied orders.yaml (context: orders-staging)" --dry-run=client -o yaml | kubectl -n "$NS" apply -f -
../_fixtures/wait-ready.sh probe

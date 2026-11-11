#!/bin/bash
kubectl -n "$NS" apply -f ../_fixtures/probe.yaml
../_fixtures/gitserver/seed.sh ledger repo "ledger-api v2.4"
../_fixtures/argo-app.sh app.yaml
../_fixtures/wait-ready.sh probe

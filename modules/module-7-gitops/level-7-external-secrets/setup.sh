#!/bin/bash
kubectl -n "$NS" apply -f ../_fixtures/probe.yaml
../_fixtures/gitserver/seed.sh ledger repo "ledger-api with its database secret"
../_fixtures/argo-app.sh app.yaml
../_fixtures/wait-ready.sh probe

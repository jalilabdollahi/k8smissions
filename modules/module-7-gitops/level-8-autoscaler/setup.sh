#!/bin/bash
kubectl -n "$NS" apply -f ../_fixtures/probe.yaml
../_fixtures/gitserver/seed.sh storefront repo "storefront: deployment, hpa and service"
../_fixtures/argo-app.sh app.yaml
../_fixtures/wait-ready.sh probe

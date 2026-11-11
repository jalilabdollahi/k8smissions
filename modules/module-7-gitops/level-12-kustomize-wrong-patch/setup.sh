#!/bin/bash
# the prod overlay is what was applied last night: it builds, applies, and changes nothing
kubectl -n "$NS" apply -f ../_fixtures/probe.yaml
../_fixtures/gitserver/seed.sh payments repo "payments: base and overlays"
kubectl kustomize repo/overlays/prod 2>/dev/null | kubectl -n "$NS" apply -f - >/dev/null
kubectl -n "$NS" label deploy/payments svc/payments k8smissions/managed=true --overwrite >/dev/null
kubectl -n "$NS" rollout status deploy/payments --timeout=120s >/dev/null
../_fixtures/wait-ready.sh probe

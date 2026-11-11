#!/bin/bash
# a slow upstream (0.6 s) lives in the namespace; Git says the client waits only 200 ms
kubectl -n "$NS" apply -f ../_fixtures/probe.yaml
kubectl -n "$NS" apply -f upstream.yaml >/dev/null
kubectl -n "$NS" label deploy,svc,cm -l '!k8smissions/managed' k8smissions/managed=true --overwrite >/dev/null 2>&1
../_fixtures/gitserver/seed.sh payments-api repo "payments-api: upstream timeout 200 ms"
../_fixtures/argo-app.sh app.yaml
kubectl -n "$NS" rollout status deploy/ledger-upstream --timeout=120s >/dev/null
../_fixtures/wait-ready.sh probe

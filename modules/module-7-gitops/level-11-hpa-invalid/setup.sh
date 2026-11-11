#!/bin/bash
# v1 is deployed and healthy; then the v2 commit lands with the new image and a broken HPA
kubectl -n "$NS" apply -f ../_fixtures/probe.yaml
../_fixtures/gitserver/seed.sh reports repo "reports v1"
../_fixtures/argo-app.sh app.yaml
until [ "$(kubectl -n argocd get app reports -o jsonpath='{.status.sync.status}/{.status.health.status}' 2>/dev/null)" = Synced/Healthy ]; do sleep 3; done
../_fixtures/gitserver/commit.sh reports v2 "reports v2: new image, tune autoscaling"
kubectl -n argocd annotate app reports argocd.argoproj.io/refresh=hard --overwrite >/dev/null
../_fixtures/wait-ready.sh probe

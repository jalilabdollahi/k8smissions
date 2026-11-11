#!/bin/bash
for n in shop-dev shop-prod; do
  kubectl create namespace $n
  kubectl label namespace $n k8smissions/managed=true
done
kubectl -n "$NS" apply -f ../_fixtures/probe.yaml
../_fixtures/gitserver/seed.sh shop repo "shop: base, dev and prod overlays"
../_fixtures/argo-app.sh app.yaml
../_fixtures/wait-ready.sh probe

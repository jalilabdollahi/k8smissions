#!/bin/bash
# shop-prod: the real production set. shop-staging: the same production overlay applied by mistake,
# then the staging overlay on top, with a pod quota that the prod pods already use up.
for n in shop-prod shop-staging; do
  kubectl create namespace $n
  kubectl label namespace $n k8smissions/managed=true
done
kubectl -n "$NS" apply -f ../_fixtures/probe.yaml
../_fixtures/gitserver/seed.sh shop repo "shop: base and overlays"

kubectl kustomize repo/overlays/production | kubectl apply -n shop-prod -f - >/dev/null
kubectl kustomize repo/overlays/production | kubectl apply -n shop-staging -f - >/dev/null
kubectl apply -n shop-staging -f - >/dev/null <<'Q'
apiVersion: v1
kind: ResourceQuota
metadata:
  name: staging-pods
spec:
  hard:
    pods: "4"
Q
sleep 5
kubectl kustomize repo/overlays/staging | kubectl apply -n shop-staging -f - >/dev/null
../_fixtures/wait-ready.sh probe

#!/bin/bash
# the controller must be fully rolled out and serving its admission webhook before the Ingress is applied
kubectl -n ingress-nginx rollout status deploy/ingress-nginx-controller --timeout=180s
kubectl -n "$NS" apply -f ../_fixtures/probe.yaml
../_fixtures/wait-ready.sh probe
echo "probe ready: send requests to the ingress controller Service with a Host header"

#!/bin/bash
# the controller's admission webhook must be serving before the Ingress is applied
kubectl -n ingress-nginx wait --for=condition=Ready pod -l app.kubernetes.io/component=controller --timeout=180s
kubectl -n "$NS" apply -f ../_fixtures/probe.yaml
../_fixtures/wait-ready.sh probe
echo "probe ready: reach the gateway Service by name, or the ingress controller with a Host header"

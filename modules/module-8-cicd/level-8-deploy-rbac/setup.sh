#!/bin/bash
# client pod for calling the deployed storefront from inside the cluster
kubectl -n "$NS" apply -f ../../module-7-gitops/_fixtures/probe.yaml >/dev/null
../../module-7-gitops/_fixtures/wait-ready.sh probe

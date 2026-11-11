#!/bin/bash
# probe client for reaching node ports from inside the cluster
kubectl -n "$NS" apply -f ../_fixtures/probe.yaml
../_fixtures/wait-ready.sh probe
echo "probe ready: a curl client inside the cluster network, for trying node addresses"

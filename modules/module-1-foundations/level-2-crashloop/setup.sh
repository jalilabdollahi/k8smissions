#!/bin/bash
# The widget's client: lets players and the validator call rates-proxy from inside the cluster.
kubectl -n "$NS" apply -f ../_fixtures/probe.yaml
kubectl -n "$NS" label pod probe client=pricing-widget --overwrite
../_fixtures/wait-ready.sh probe

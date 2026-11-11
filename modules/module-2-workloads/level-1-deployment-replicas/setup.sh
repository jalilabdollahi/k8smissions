#!/bin/bash
# Only the in-cluster curl client; the reports Deployment comes from broken.yaml.
kubectl -n "$NS" apply -f ../_fixtures/probe.yaml
../_fixtures/wait-ready.sh probe
echo "client ready: the reports team is waiting for their dashboards"

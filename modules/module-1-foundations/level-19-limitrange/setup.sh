#!/bin/bash
# The month-end batch client posts render jobs from this pod.
kubectl -n "$NS" apply -f ../_fixtures/probe.yaml
kubectl -n "$NS" annotate pod probe batch-client="requests /render on Service invoice-render" --overwrite
../_fixtures/wait-ready.sh probe

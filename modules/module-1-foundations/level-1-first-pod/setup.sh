#!/bin/bash
# The intern's pod is the only thing under test; the probe is how we look at it from inside.
kubectl -n "$NS" apply -f ../_fixtures/probe.yaml
kubectl -n "$NS" annotate pod probe purpose="check the welcome page from inside the cluster" --overwrite
../_fixtures/wait-ready.sh probe

#!/bin/bash
# The request loop in validate.sh and the player's checks run from this curl pod.
kubectl -n "$NS" apply -f ../_fixtures/probe.yaml
kubectl -n "$NS" wait --for=condition=Ready pod/probe --timeout=120s >/dev/null

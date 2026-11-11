#!/bin/bash
# The treasury dashboard fetches rates from this pod.
kubectl -n "$NS" apply -f ../_fixtures/probe.yaml
kubectl -n "$NS" annotate pod probe treasury-fetch="polls Service rates-sync for the EUR table" --overwrite
../_fixtures/wait-ready.sh probe

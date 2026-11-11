#!/bin/bash
# Curl client for checking inventory through its Service after the probe fix.
kubectl -n "$NS" apply -f ../_fixtures/probe.yaml
../_fixtures/wait-ready.sh probe
echo "client ready: inventory pods will be created next"

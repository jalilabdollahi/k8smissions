#!/bin/bash
# nslookup/curl client used to look at the quorum DNS name from outside the StatefulSet
kubectl -n "$NS" apply -f ../_fixtures/probe.yaml
../_fixtures/wait-ready.sh probe
echo "probe ready: query the quorum name from here and compare it with the pods"

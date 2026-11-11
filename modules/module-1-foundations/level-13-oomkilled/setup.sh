#!/bin/bash
# Image requests reach thumbnailer from this gateway pod.
kubectl -n "$NS" apply -f ../_fixtures/probe.yaml
kubectl -n "$NS" annotate pod probe gateway-role="sends thumbnail requests to Service thumbnailer" --overwrite
../_fixtures/wait-ready.sh probe

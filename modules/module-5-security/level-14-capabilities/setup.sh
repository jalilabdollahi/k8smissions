#!/bin/bash
NS=${NS:-k8smissions}
kubectl -n "$NS" apply -f ../_fixtures/probe.yaml
../_fixtures/wait-ready.sh probe

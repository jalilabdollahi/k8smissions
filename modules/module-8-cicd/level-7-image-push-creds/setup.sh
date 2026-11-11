#!/bin/bash
# registry with basic auth (user ci-push) and a client pod for probing it
../_fixtures/registry.sh 'ci-push:$2y$05$KxnGdWG5.6ypS5OWlHKljuJmQaCcsV9f66Bzqb/4/pZe0nC6xgek2'
kubectl -n "$NS" apply -f ../../module-7-gitops/_fixtures/probe.yaml >/dev/null
../../module-7-gitops/_fixtures/wait-ready.sh probe

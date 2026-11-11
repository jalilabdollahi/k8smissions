#!/bin/bash
# 1. The lease is held by a pod that no longer exists, with a ten year duration: let a live replicator take over.
kubectl -n eu delete lease eu-leader
# 2. us only admits namespaces labelled region=eu.
kubectl label namespace eu region=eu
# 3. The us copy of the token ends in a newline (created with echo): recreate it without one.
tok=$(kubectl -n eu get secret replication-token -o jsonpath='{.data.token}' | base64 -d)
kubectl -n us create secret generic replication-token --from-literal=token="$tok" --dry-run=client -o yaml | kubectl apply -f -
# the store reads the token when it starts
kubectl -n us rollout restart deploy/store
kubectl -n us rollout status deploy/store --timeout=120s

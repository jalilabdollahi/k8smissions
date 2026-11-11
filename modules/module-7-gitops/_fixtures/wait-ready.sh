#!/bin/bash
# Block until the named pods in $NS are Ready. Usage: wait-ready.sh probe [other-pod ...]
for p in "$@"; do
  kubectl -n "${NS:-k8smissions}" wait --for=condition=Ready "pod/$p" --timeout=120s >/dev/null
done

#!/bin/bash
# usage: wait-ready.sh pod [pod...]   (namespace from $NS)
for p in "$@"; do
  kubectl -n "${NS:-k8smissions}" wait --for=condition=Ready "pod/$p" --timeout=120s >/dev/null || exit 1
done

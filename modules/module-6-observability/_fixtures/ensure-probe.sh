#!/bin/bash
# usage: ensure-probe.sh   (namespace from $NS)
# Creates the `probe` curl pod (probe.yaml) if it is not there yet and waits until it is Ready.
# Validators call it so a level does not need its own setup.sh just for a client pod.
here="$(cd "$(dirname "$0")" && pwd)"
ns="${NS:-k8smissions}"
kubectl -n "$ns" get pod probe >/dev/null 2>&1 || kubectl -n "$ns" apply -f "$here/probe.yaml" >/dev/null 2>&1
kubectl -n "$ns" wait --for=condition=Ready pod/probe --timeout=60s >/dev/null 2>&1

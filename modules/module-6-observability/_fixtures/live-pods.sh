#!/bin/bash
# usage: live-pods.sh [-n namespace] <label-selector>
# Prints the names of the Running pods that match the selector and are not being deleted.
# (kubectl's jsonpath cannot test "has no deletionTimestamp", so validators use this.)
NSARG="${NS:-k8smissions}"
if [ "$1" = "-n" ]; then NSARG="$2"; shift 2; fi
kubectl -n "$NSARG" get pods -l "$1" -o json 2>/dev/null | python3 -c '
import json, sys
try:
    items = json.load(sys.stdin)["items"]
except Exception:
    items = []
for p in items:
    if not p["metadata"].get("deletionTimestamp") and p.get("status", {}).get("phase") == "Running":
        print(p["metadata"]["name"])
'

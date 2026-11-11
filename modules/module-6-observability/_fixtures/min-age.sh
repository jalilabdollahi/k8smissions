#!/bin/bash
# usage: min-age.sh [-n namespace] <label-selector>
# Prints the age in seconds of the youngest pod that matches the selector and
# is not being deleted (0 when there is none). Validators use it to make sure a
# pod has outlived the failure window of the broken state before calling it fixed.
# Works on macOS and Linux (no GNU date).
NSARG="${NS:-k8smissions}"
if [ "$1" = "-n" ]; then NSARG="$2"; shift 2; fi
kubectl -n "$NSARG" get pods -l "$1" -o json 2>/dev/null | python3 -c '
import json, sys, time, datetime
try:
    items = json.load(sys.stdin)["items"]
except Exception:
    items = []
ages = []
for p in items:
    if p["metadata"].get("deletionTimestamp") or p.get("status", {}).get("phase") != "Running":
        continue
    t = datetime.datetime.strptime(p["metadata"]["creationTimestamp"], "%Y-%m-%dT%H:%M:%SZ").replace(tzinfo=datetime.timezone.utc)
    ages.append(int(time.time() - t.timestamp()))
print(min(ages) if ages else 0)
'

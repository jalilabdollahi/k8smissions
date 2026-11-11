#!/bin/bash
# Real Helm history for release "webapp": 1 ok, 2 ok (v2), 3 crash-loops, 4 failed (timed out).
kubectl -n "$NS" apply -f ../_fixtures/probe.yaml
h() { helm -n "$NS" "$@" >/dev/null 2>&1; }
h install webapp chart --wait --timeout 90s
h upgrade webapp chart --reuse-values --set payloadText="webapp v2: checkout ready" --wait --timeout 60s
h upgrade webapp chart --reuse-values --set configKey=body --set payloadText="webapp v3: new banner"
sleep 3
h upgrade webapp chart --reuse-values --set resources.requests.cpu=500 --wait --timeout 20s
../_fixtures/wait-ready.sh probe
helm -n "$NS" history webapp | tail -4 >&2

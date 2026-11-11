#!/bin/bash
# 96 leftovers from weeks of nightly exporter runs: export-result-0001 .. 0096.
# They exist before the quota does, so the namespace starts exactly at its limit.
. ../_fixtures/lib.sh
for i in $(seq 1 96); do
  n=$(printf %04d "$i")
  printf -- '---\napiVersion: v1\nkind: ConfigMap\nmetadata:\n  name: export-result-%s\n  namespace: %s\n  labels:\n    app: exporter\ndata:\n  rows: "%s"\n  run: "nightly-%s"\n' \
    "$n" "$NS" "$((1000 + 37 * i))" "$n"
done | kubectl apply -f -

#!/bin/bash
# Real Helm history: revision 1 is the production install, revision 2 is CI's "--set image.tag" upgrade.
set -e
kubectl -n "$NS" apply -f ../_fixtures/probe.yaml
../_fixtures/gitserver/seed.sh charts repo "ledger-api chart 0.4.0"

prod=$(mktemp)
cat > "$prod" <<'VALUES'
replicaCount: 3
image:
  repository: hashicorp/http-echo
  tag: "0.2.3"
message: "ledger-api: production"
VALUES
helm -n "$NS" install ledger-api repo/ledger-api -f "$prod" --wait --timeout 90s >/dev/null
helm -n "$NS" upgrade ledger-api repo/ledger-api --set image.tag=1.0 >/dev/null
rm -f "$prod"
../_fixtures/wait-ready.sh probe

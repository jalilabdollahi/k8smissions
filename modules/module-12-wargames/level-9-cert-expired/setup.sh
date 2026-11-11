#!/bin/bash
# The internal CA (key included, as the platform team keeps it in the namespace) and the two
# certificates that expired in 2024. The certificates are committed fixtures (../_fixtures/certs).
NS=${NS:-k8smissions}
C=../_fixtures/certs
CA=../../module-10-operators/_fixtures/certs/ca-a
kubectl -n "$NS" create secret generic internal-ca --from-file=ca.crt="$CA/ca.crt" --from-file=ca.key="$CA/ca.key" >/dev/null || exit 1
kubectl -n "$NS" create configmap internal-ca-bundle --from-file=ca.crt="$CA/ca.crt" >/dev/null || exit 1
kubectl -n "$NS" create secret tls ledger-tls --cert="$C/ledger-expired/tls.crt" --key="$C/ledger-expired/tls.key" >/dev/null || exit 1
kubectl -n "$NS" create secret tls gateway-client-tls --cert="$C/gateway-expired/tls.crt" --key="$C/gateway-expired/tls.key" >/dev/null || exit 1

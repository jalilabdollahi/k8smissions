#!/bin/bash
NS=k8smissions
# the webhook Service has no selector and its hand-written Endpoints point at a dead address
kubectl -n $NS patch svc config-guard --type=merge -p '{"spec":{"selector":{"app":"config-guard"}}}'
kubectl -n $NS delete endpoints config-guard --ignore-not-found
# the caBundle trusts the wrong CA: the right one is stored next to the server's certificate
ca=$(kubectl -n $NS get secret config-guard-tls -o jsonpath='{.data.ca\.crt}')
kubectl patch validatingwebhookconfiguration config-guard --type=json \
  -p "[{\"op\":\"replace\",\"path\":\"/webhooks/0/clientConfig/caBundle\",\"value\":\"$ca\"}]"
# the noisy client
kubectl -n $NS set env deploy/inventory-sync POLL_INTERVAL_MS=30000
kubectl -n $NS rollout status deploy/inventory-sync --timeout=90s
sleep 12

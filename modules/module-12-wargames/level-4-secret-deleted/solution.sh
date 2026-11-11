#!/bin/bash
NS=k8smissions
# the pods that still run hold the original password in their environment
pod=$(kubectl -n $NS get pods -l app=billing-api --field-selector=status.phase=Running -o jsonpath='{.items[0].metadata.name}')
pw=$(kubectl -n $NS exec "$pod" -- printenv DB_PASSWORD)
# the API reads key "password"; invoice-export reads key "DB_PASS"
kubectl -n $NS create secret generic db-credentials \
  --from-literal=username=billing --from-literal=password="$pw" --from-literal=DB_PASS="$pw"
kubectl -n $NS rollout status deploy/billing-api --timeout=150s

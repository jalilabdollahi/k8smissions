#!/bin/bash
NS=k8smissions
# the node that holds the volume was cordoned for the drill
for n in $(kubectl get nodes -o jsonpath='{.items[?(@.spec.unschedulable==true)].metadata.name}'); do
  kubectl uncordon "$n"
done
# the Service selects a label the pods do not carry
kubectl -n $NS patch svc ledger-db --type=json -p='[{"op":"replace","path":"/spec/selector","value":{"app":"ledger-db"}}]'
# the policy admits tier=app, the application pods are tier=backend
kubectl -n $NS patch networkpolicy ledger-db-ingress --type=json \
  -p='[{"op":"replace","path":"/spec/ingress/0/from/0/podSelector/matchLabels","value":{"tier":"backend"}}]'
kubectl -n $NS rollout status sts/ledger-db --timeout=120s

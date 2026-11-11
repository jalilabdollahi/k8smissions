#!/bin/bash
kubectl -n k8smissions get pipelinerun release-ledger-0907 -o jsonpath='{.status.childReferences}'; echo
kubectl -n k8smissions get pipelinerun release-ledger-0907 -o jsonpath='{.status.conditions[0].reason}'; echo
kubectl -n k8smissions rollout history deployment/ledger-api
kubectl -n k8smissions patch deployment ledger-api --type=merge -p '{"spec":{"revisionHistoryLimit":5}}'
kubectl -n k8smissions patch pipeline release-ledger --type=json \
  -p '[{"op":"replace","path":"/spec/finally/0/when/0/values","value":["Failed"]}]'

#!/bin/bash
# The Released volume still points at the deleted claim; clear that pointer so the new claim can take it.
kubectl describe pvc billing-data -n k8smissions | tail -4
kubectl get pv billing-pv -o jsonpath='{.spec.claimRef}'; echo
kubectl patch pv billing-pv --type=merge -p '{"spec":{"claimRef":null}}'
kubectl wait pvc/billing-data -n k8smissions --for=jsonpath='{.status.phase}'=Bound --timeout=60s
kubectl rollout status deployment/billing-reader -n k8smissions --timeout=100s

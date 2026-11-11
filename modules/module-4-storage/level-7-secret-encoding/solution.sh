#!/bin/bash
kubectl get secret db-credentials -n k8smissions -o jsonpath='{.data.password}' | base64 -d | od -c
kubectl create secret generic db-credentials -n k8smissions \
  --from-literal=username=ledger --from-literal=password=Ledg3r-9fQ2x \
  --dry-run=client -o yaml | kubectl apply -f -
# mounted Secret files refresh lazily; restart so the new value is read now
kubectl rollout restart deployment/db-client -n k8smissions
kubectl rollout status deployment/db-client -n k8smissions --timeout=100s

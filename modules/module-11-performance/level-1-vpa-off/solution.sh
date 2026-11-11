#!/bin/bash
# Observed working set is about 190Mi: size from that, then add the third replica.
kubectl set resources deployment/search-indexer -n k8smissions \
  --requests=memory=224Mi --limits=memory=320Mi
kubectl scale deployment/search-indexer -n k8smissions --replicas=3
kubectl rollout status deployment/search-indexer -n k8smissions --timeout=120s

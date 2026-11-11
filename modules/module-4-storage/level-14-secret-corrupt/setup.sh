#!/bin/bash
# Reproduces last night's rotation: the consumer started with token v1 and the Secret was
# then rotated to v2. The Secret lives here (not in broken.yaml) so that the engine applying
# broken.yaml afterwards does not reset it to v1.
kubectl create secret generic api-token -n "$NS" --from-literal=token=tok-2025-11-a91f3c \
  --dry-run=client -o yaml | kubectl apply -f - >/dev/null
kubectl apply -f broken.yaml >/dev/null
kubectl rollout status deployment/api-gateway -n "$NS" --timeout=120s >/dev/null || exit 1
kubectl rollout status deployment/api-consumer -n "$NS" --timeout=120s >/dev/null || exit 1
kubectl create secret generic api-token -n "$NS" --from-literal=token=tok-2025-11-7be204 \
  --dry-run=client -o yaml | kubectl apply -f - >/dev/null
exit 0

#!/bin/bash
# 6 steady pods + 2 surge pods = 8 x pool must stay <= 20, so pool 2 (16).
kubectl set env deployment/cart-api -n k8smissions DB_POOL_SIZE=2
kubectl rollout status deployment/cart-api -n k8smissions --timeout=120s

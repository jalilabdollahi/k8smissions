#!/bin/bash
# Right-size the requests to what payments-web actually uses; the surge pod then fits under the quota.
kubectl top pod -n k8smissions -l app=payments-web 2>/dev/null || true
kubectl set resources deployment/payments-web -n k8smissions --requests=cpu=100m
kubectl rollout status deployment/payments-web -n k8smissions --timeout=90s

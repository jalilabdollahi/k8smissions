#!/bin/bash
# Throttling shows in cpu.stat, not in kubectl top. Raise the limit well above the burst demand.
kubectl set resources deployment/quote-api -n k8smissions --requests=cpu=100m --limits=cpu=500m
kubectl rollout status deployment/quote-api -n k8smissions --timeout=90s

#!/bin/bash
# profile-api leaks: bound its cache. render-svc plateaus above its limit: raise the limit.
kubectl set env deployment/profile-api -n k8smissions CACHE_MAX_MB=48
kubectl set resources deployment/render-svc -n k8smissions --requests=memory=224Mi --limits=memory=288Mi
kubectl rollout status deployment/profile-api -n k8smissions --timeout=90s
kubectl rollout status deployment/render-svc -n k8smissions --timeout=90s

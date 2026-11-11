#!/bin/bash
# The pods wait for catalog.k8smissions.io/warm, the controller writes catalog.k8smissions.io/warmed.
# Make the controller write the type the pods are gated on.
kubectl set env deployment/warmup-gate -n k8smissions CONDITION_TYPE=catalog.k8smissions.io/warm
kubectl rollout status deployment/warmup-gate -n k8smissions --timeout=60s
kubectl rollout status deployment/catalog-web -n k8smissions --timeout=90s

#!/bin/bash
# Three layers: DNS search expansion, the CPU limit on pricing, session affinity on the pricing Service.
kubectl set env deployment/storefront -n k8smissions PRICING_HOST=pricing.catalog.internal.
kubectl set resources deployment/pricing -n k8smissions --requests=cpu=100m --limits=cpu=1
kubectl patch service pricing -n k8smissions -p '{"spec":{"sessionAffinity":"None"}}'
kubectl rollout status deployment/pricing -n k8smissions --timeout=90s
kubectl rollout status deployment/storefront -n k8smissions --timeout=90s

#!/bin/bash
# quotas.payments.internal has 2 dots; with ndots:5 it is tried with every search suffix first.
# ndots:2 makes the resolver try a name with 2 or more dots as an absolute name first.
kubectl patch deployment rate-limiter -n k8smissions --type=json \
  -p '[{"op":"replace","path":"/spec/template/spec/dnsConfig/options/0/value","value":"2"}]'
kubectl rollout status deployment/rate-limiter -n k8smissions --timeout=90s

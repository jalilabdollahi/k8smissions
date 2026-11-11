#!/bin/bash
# Two faults: the gateways bypass the cache, and the cache expires every answer after one second.
kubectl patch deployment session-gw -n k8smissions --type=json \
  -p '[{"op":"replace","path":"/spec/template/spec/dnsConfig/nameservers/0","value":"10.96.150.111"}]'
kubectl apply -n k8smissions -f - <<'EOF'
apiVersion: v1
kind: ConfigMap
metadata:
  name: dns-cache-corefile
data:
  Corefile: |
    .:53 {
        log
        health
        cache {
            success 9984 300
        }
        forward . 10.96.150.110
    }
EOF
kubectl rollout restart daemonset/dns-cache -n k8smissions
kubectl rollout status daemonset/dns-cache -n k8smissions --timeout=90s
kubectl rollout status deployment/session-gw -n k8smissions --timeout=90s

#!/bin/bash
NS=k8smissions
# Bootstrap deadlock: members are Ready only with quorum, and DNS only lists Ready pods.
kubectl -n $NS patch svc kv-peers --type=merge -p '{"spec":{"publishNotReadyAddresses":true}}'
# Policy: peers also talk on 9000 (both directions) and every member needs DNS.
kubectl -n $NS apply -f - <<'EOF'
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: kv-lockdown
  namespace: k8smissions
spec:
  podSelector:
    matchLabels: {app: kv}
  policyTypes: [Ingress, Egress]
  ingress:
  - from:
    - podSelector: {matchLabels: {app: kv}}
    ports:
    - {port: 8080, protocol: TCP}
    - {port: 9000, protocol: TCP}
  - from:
    - podSelector: {matchLabels: {role: kv-client}}
    ports:
    - {port: 8080, protocol: TCP}
  egress:
  - to:
    - podSelector: {matchLabels: {app: kv}}
    ports:
    - {port: 8080, protocol: TCP}
    - {port: 9000, protocol: TCP}
  - to:
    - namespaceSelector: {matchLabels: {kubernetes.io/metadata.name: kube-system}}
      podSelector: {matchLabels: {k8s-app: kube-dns}}
    ports:
    - {port: 53, protocol: UDP}
    - {port: 53, protocol: TCP}
EOF
kubectl -n $NS rollout status sts/kv --timeout=120s

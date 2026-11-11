#!/bin/bash
# One RWO volume lives on one node; a hard spread rule can never put 3 pods on 2+ nodes.
kubectl get pods -n k8smissions -l app=web-servers -o wide
kubectl describe pod -n k8smissions -l app=web-servers | grep -m1 -A1 FailedScheduling
kubectl patch deployment web-servers -n k8smissions --type=json \
  -p '[{"op":"replace","path":"/spec/template/spec/topologySpreadConstraints/0/whenUnsatisfiable","value":"ScheduleAnyway"}]'
kubectl rollout status deployment/web-servers -n k8smissions --timeout=120s

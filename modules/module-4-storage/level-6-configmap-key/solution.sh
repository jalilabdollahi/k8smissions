#!/bin/bash
kubectl describe pod -n k8smissions -l app=web-app | grep -A2 -i 'non-existent'
kubectl get configmap app-config -n k8smissions -o jsonpath='{.data}' | head -c 200; echo
kubectl patch deployment web-app -n k8smissions --type=json \
  -p '[{"op":"replace","path":"/spec/template/spec/volumes/1/configMap/items/0/key","value":"app.yaml"}]'
kubectl rollout status deployment/web-app -n k8smissions --timeout=80s

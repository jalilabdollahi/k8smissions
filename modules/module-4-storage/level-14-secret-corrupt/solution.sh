#!/bin/bash
# A subPath mount of a Secret never receives updates; mount the whole volume instead.
kubectl get secret api-token -n k8smissions -o jsonpath='{.data.token}' | base64 -d; echo
kubectl exec -n k8smissions deploy/api-consumer -- cat /etc/api/token; echo
kubectl get deployment api-consumer -n k8smissions -o jsonpath='{.spec.template.spec.containers[0].volumeMounts}'; echo
kubectl patch deployment api-consumer -n k8smissions --type=json \
  -p '[{"op":"replace","path":"/spec/template/spec/containers/0/volumeMounts/1","value":{"name":"token","mountPath":"/etc/api","readOnly":true}}]'
kubectl rollout status deployment/api-consumer -n k8smissions --timeout=100s

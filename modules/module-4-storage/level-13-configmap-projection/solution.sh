#!/bin/bash
# Both sources define a key called db.password; the ConfigMap's empty one is listed last and wins.
kubectl exec -n k8smissions deploy/config-reader -- sh -c 'ls -l /etc/db; wc -c /etc/db/db.password'
kubectl get deployment config-reader -n k8smissions -o jsonpath='{.spec.template.spec.volumes[1].projected}'; echo
kubectl get configmap db-config -n k8smissions -o jsonpath='{.data}'; echo
# project only the key we need from the ConfigMap
kubectl patch deployment config-reader -n k8smissions --type=json -p '[
  {"op":"replace","path":"/spec/template/spec/volumes/1/projected/sources/1",
   "value":{"configMap":{"name":"db-config","items":[{"key":"db.url","path":"db.url"}]}}}]'
kubectl rollout status deployment/config-reader -n k8smissions --timeout=100s

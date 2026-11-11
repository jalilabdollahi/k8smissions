#!/bin/bash
NS=k8smissions
# 1. PID 1 is the python server and never reaps orphans: share the pod's PID namespace so the pause container is PID 1.
# 2+3. probes on the endpoint that needs the process table to work.
kubectl -n $NS patch deploy thumb-worker -p '{
 "spec":{"template":{"spec":{
  "shareProcessNamespace": true,
  "containers":[{"name":"worker",
   "readinessProbe":{"httpGet":{"path":"/healthz","port":8080},"periodSeconds":3,"timeoutSeconds":1,"failureThreshold":2},
   "livenessProbe":{"httpGet":{"path":"/healthz","port":8080},"periodSeconds":3,"timeoutSeconds":1,"failureThreshold":2}}]}}}}'
kubectl -n $NS rollout status deploy/thumb-worker --timeout=120s

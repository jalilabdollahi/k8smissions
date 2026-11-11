#!/bin/bash
CK=checkout
# Act 1: namespace enforces "restricted": run non-root with a seccomp profile, no privilege escalation, no capabilities (every container).
# Act 2: the nodeSelector value has a typo (pool=general).
# Act 3: the liveness probe starts at 5s but the app needs ~25s: a startupProbe holds liveness back.
# Act 4 (part): the sidecar has no CPU request.
kubectl -n $CK patch deploy checkout -p '{"spec":{"template":{"spec":{
 "nodeSelector":{"pool":"general"},
 "securityContext":{"runAsNonRoot":true,"runAsUser":10001,"seccompProfile":{"type":"RuntimeDefault"}},
 "containers":[
  {"name":"app","securityContext":{"allowPrivilegeEscalation":false,"capabilities":{"drop":["ALL"]}},
   "startupProbe":{"httpGet":{"path":"/healthz","port":8080},"periodSeconds":5,"failureThreshold":12}},
  {"name":"log-shipper","securityContext":{"allowPrivilegeEscalation":false,"capabilities":{"drop":["ALL"]}},
   "resources":{"requests":{"cpu":"10m","memory":"16Mi"}}}]}}}}'
# Act 2: the leftover taint on the workers
kubectl taint nodes -l pool=general dedicated-
# Act 4: the HPA watches memory and may not exceed 2 replicas
kubectl -n $CK patch hpa checkout --type=merge -p '{"spec":{"maxReplicas":6,"metrics":[{"type":"Resource","resource":{"name":"cpu","target":{"type":"Utilization","averageUtilization":50}}}]}}'
kubectl -n $CK rollout status deploy/checkout --timeout=180s

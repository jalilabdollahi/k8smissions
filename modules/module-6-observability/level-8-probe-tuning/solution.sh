kubectl -n k8smissions describe pod -l app=search-api | grep -E 'Liveness|Readiness|Unhealthy'
kubectl -n k8smissions exec deploy/search-load -- sh -c 'time wget -q -O /dev/null http://search-api/healthz'
kubectl -n k8smissions patch deploy search-api --type=json -p='[
 {"op":"add","path":"/spec/template/spec/containers/0/livenessProbe/timeoutSeconds","value":10},
 {"op":"add","path":"/spec/template/spec/containers/0/readinessProbe/timeoutSeconds","value":10}
]'
kubectl -n k8smissions rollout status deploy/search-api --timeout=120s

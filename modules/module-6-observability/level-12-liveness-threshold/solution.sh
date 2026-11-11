kubectl -n k8smissions describe pod -l app=report-engine | grep -E 'Liveness|Restart Count|Unhealthy'
kubectl -n k8smissions logs deploy/report-engine --previous | tail -5
kubectl -n k8smissions patch deploy report-engine --type=json \
  -p='[{"op":"replace","path":"/spec/template/spec/containers/0/livenessProbe/failureThreshold","value":6}]'
kubectl -n k8smissions rollout status deploy/report-engine --timeout=90s

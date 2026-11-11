kubectl -n k8smissions get pods
kubectl -n k8smissions describe pod -l app=inventory
kubectl -n k8smissions logs -l app=inventory --previous --tail=5
kubectl -n k8smissions patch deployment inventory --type=json -p '[{"op":"replace","path":"/spec/template/spec/containers/0/livenessProbe/initialDelaySeconds","value":30},{"op":"replace","path":"/spec/template/spec/containers/0/livenessProbe/failureThreshold","value":3}]'
kubectl -n k8smissions rollout status deployment/inventory --timeout=120s

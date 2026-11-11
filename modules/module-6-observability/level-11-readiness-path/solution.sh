kubectl -n k8smissions rollout status deploy/docs-site --timeout=5s
kubectl -n k8smissions describe pod -l app=docs-site | grep -A2 -i 'readiness probe failed' | head
kubectl -n k8smissions get cm docs-site-conf-v2 -o jsonpath='{.data.default\.conf}'
kubectl -n k8smissions patch deploy docs-site --type=json \
  -p='[{"op":"replace","path":"/spec/template/spec/containers/0/readinessProbe/httpGet/path","value":"/-/health"}]'
kubectl -n k8smissions rollout status deploy/docs-site --timeout=100s

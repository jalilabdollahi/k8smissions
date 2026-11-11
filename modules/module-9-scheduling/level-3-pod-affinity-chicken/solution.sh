kubectl -n k8smissions get pods
kubectl -n k8smissions describe pod -l tier=cache | grep -A3 Events
kubectl -n k8smissions get deploy reports-cache -o jsonpath='{.spec.template.spec.affinity}'
kubectl -n k8smissions patch deploy reports-cache --type=json -p '[{"op":"remove","path":"/spec/template/spec/affinity"}]'
kubectl -n k8smissions rollout status deploy/reports-cache --timeout=90s
kubectl -n k8smissions rollout status deploy/reports-web --timeout=90s
kubectl -n k8smissions get pods -o wide

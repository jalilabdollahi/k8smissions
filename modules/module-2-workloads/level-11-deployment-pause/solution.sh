kubectl -n k8smissions get deployment frontend -o jsonpath='{.spec.paused}{"\n"}'
kubectl -n k8smissions rollout resume deployment/frontend
kubectl -n k8smissions rollout status deployment/frontend --timeout=100s

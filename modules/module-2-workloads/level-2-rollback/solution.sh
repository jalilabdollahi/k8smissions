kubectl -n k8smissions rollout history deployment/web-app
kubectl -n k8smissions rollout undo deployment/web-app
kubectl -n k8smissions rollout status deployment/web-app --timeout=100s

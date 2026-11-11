kubectl -n k8smissions get pods
kubectl -n k8smissions get events --sort-by=.lastTimestamp
kubectl -n k8smissions describe rs -l app=billing-worker | tail -8
kubectl -n k8smissions create serviceaccount billing-sa
kubectl -n k8smissions rollout status deploy/billing-worker --timeout=100s

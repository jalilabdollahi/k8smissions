kubectl -n k8smissions get deployment reports
kubectl -n k8smissions get rs
kubectl -n k8smissions describe rs -l app=reports
kubectl -n k8smissions create serviceaccount reports-sa
kubectl -n k8smissions rollout status deployment/reports --timeout=90s

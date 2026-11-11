kubectl -n k8smissions get rs
kubectl -n k8smissions describe rs -l app=invoice-api | tail -8
kubectl -n k8smissions describe quota team-quota
kubectl -n k8smissions set resources deployment invoice-api --limits=cpu=500m,memory=512Mi
kubectl -n k8smissions rollout status deploy/invoice-api --timeout=90s

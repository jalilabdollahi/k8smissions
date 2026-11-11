kubectl -n k8smissions get hpa web-backend
kubectl -n k8smissions describe hpa web-backend
kubectl -n k8smissions top pods --containers
kubectl -n k8smissions set resources deployment web-backend -c log-forwarder --requests=cpu=20m
kubectl -n k8smissions rollout status deployment/web-backend --timeout=120s

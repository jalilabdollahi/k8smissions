kubectl -n k8smissions logs deploy/quote-service --all-containers --prefix
kubectl -n k8smissions logs deploy/quote-service -c app --previous
kubectl -n k8smissions set env deploy/quote-service -c metrics-proxy LISTEN_PORT=9102
kubectl -n k8smissions rollout status deploy/quote-service --timeout=100s

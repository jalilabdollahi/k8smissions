kubectl -n k8smissions logs deploy/orders-web --tail=2
kubectl get deploy,svc -A | grep orders
kubectl -n k8smissions set env deployment/orders-web UPSTREAM=http://orders-api.orders-staging.svc.cluster.local
kubectl -n k8smissions rollout status deployment/orders-web --timeout=60s

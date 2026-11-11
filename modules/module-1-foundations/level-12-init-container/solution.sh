kubectl -n k8smissions get pods
kubectl -n k8smissions logs deploy/ledger-web -c wait-for-db --tail=3
kubectl -n k8smissions get endpoints ledger-db
kubectl -n k8smissions get deployment ledger-db
kubectl -n k8smissions scale deployment ledger-db --replicas=1
kubectl -n k8smissions rollout status deployment/ledger-db --timeout=60s
kubectl -n k8smissions rollout status deployment/ledger-web --timeout=60s

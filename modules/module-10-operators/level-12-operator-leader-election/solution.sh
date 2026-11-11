kubectl -n k8smissions get lease
kubectl -n k8smissions get lease -o custom-columns=NAME:.metadata.name,HOLDER:.spec.holderIdentity
kubectl -n k8smissions set env deploy/orders-operator LEASE_NAME=orders-operator-leader
kubectl -n k8smissions rollout status deploy/orders-operator --timeout=120s

kubectl -n k8smissions exec probe -- nslookup inventory
kubectl get svc -A | grep inventory
kubectl -n k8smissions set env deployment/storefront INVENTORY_URL=http://inventory.warehouse.svc.cluster.local:8080
kubectl -n k8smissions rollout status deployment/storefront --timeout=120s
kubectl -n warehouse describe networkpolicy
kubectl get ns --show-labels
kubectl label namespace k8smissions team=storefront

kubectl -n k8smissions get svc shop -o yaml
kubectl -n k8smissions get pods --show-labels
kubectl -n k8smissions get endpoints shop
kubectl -n k8smissions patch service shop --type=merge -p '{"spec":{"selector":{"version":null,"release":"green"}}}'
kubectl -n k8smissions get endpoints shop

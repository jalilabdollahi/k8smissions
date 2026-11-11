kubectl -n k8smissions get configmap export-lock -o yaml
kubectl -n k8smissions create configmap export-lock --from-literal=owner=billing
kubectl -n k8smissions patch configmap export-lock --type=merge -p '{"metadata":{"finalizers":null}}'
kubectl -n k8smissions create configmap export-lock --from-literal=owner=billing
kubectl -n k8smissions get configmap export-lock -o yaml

kubectl -n k8smissions logs deploy/webapp-operator
kubectl -n k8smissions get cm operator-config -o yaml | grep -A3 '^data'
kubectl -n k8smissions patch configmap operator-config --type=merge -p '{"data":{"watch-namespace":"k8smissions"}}'
kubectl -n k8smissions rollout restart deployment/webapp-operator
kubectl -n k8smissions rollout status deployment/webapp-operator --timeout=90s

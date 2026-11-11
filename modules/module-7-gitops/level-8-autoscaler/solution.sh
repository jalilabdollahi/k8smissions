kubectl -n argocd get app storefront -o jsonpath='{.status.sync.status}{"\n"}'
kubectl -n k8smissions get hpa storefront
kubectl -n k8smissions get rs -l app=storefront
kubectl -n argocd patch app storefront --type merge -p '{
  "spec": {
    "ignoreDifferences": [{"group": "apps", "kind": "Deployment", "jsonPointers": ["/spec/replicas"]}],
    "syncPolicy": {"syncOptions": ["RespectIgnoreDifferences=true"]}
  }
}'
until [ "$(kubectl -n k8smissions get deploy storefront -o jsonpath='{.status.readyReplicas}')" -ge 3 ] 2>/dev/null; do sleep 3; done
kubectl -n k8smissions get deploy storefront

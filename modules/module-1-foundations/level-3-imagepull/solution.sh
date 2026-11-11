kubectl -n k8smissions get pods -l app=storefront
POD=$(kubectl -n k8smissions get pods -l app=storefront -o name | head -1)
kubectl -n k8smissions describe $POD | tail -8
kubectl -n k8smissions get deploy storefront-canary -o jsonpath='{.spec.template.spec.containers[0].image}{"\n"}'
kubectl -n k8smissions set image deployment/storefront web=nginx:1.27-alpine
kubectl -n k8smissions rollout status deployment/storefront --timeout=90s

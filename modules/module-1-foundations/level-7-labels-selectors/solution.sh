kubectl -n k8smissions get endpoints blog
kubectl -n k8smissions get pods --show-labels
kubectl -n k8smissions describe service blog | grep -i selector
kubectl -n k8smissions patch deployment blog -p '{"spec":{"template":{"metadata":{"labels":{"tier":"web"}}}}}'
kubectl -n k8smissions rollout status deployment/blog --timeout=90s

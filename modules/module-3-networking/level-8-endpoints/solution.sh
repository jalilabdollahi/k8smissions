kubectl -n k8smissions get endpointslices -l kubernetes.io/service-name=search -o yaml
kubectl -n k8smissions logs deploy/search-api -c indexer --previous
kubectl -n k8smissions patch deployment search-api -p '{"spec":{"template":{"spec":{"containers":[{"name":"indexer","args":["--output","/index"]}]}}}}'
kubectl -n k8smissions rollout status deployment/search-api --timeout=120s

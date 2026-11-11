kubectl -n k8smissions logs deploy/catalog-indexer --previous | tail -3
kubectl -n k8smissions describe pod -l app=catalog-indexer | grep -E 'Liveness|Killing|Started'
kubectl -n k8smissions patch deploy catalog-indexer --type=json -p='[
 {"op":"add","path":"/spec/template/spec/containers/0/startupProbe","value":
   {"httpGet":{"path":"/healthz","port":8080},"periodSeconds":5,"failureThreshold":18}}
]'
kubectl -n k8smissions rollout status deploy/catalog-indexer --timeout=150s

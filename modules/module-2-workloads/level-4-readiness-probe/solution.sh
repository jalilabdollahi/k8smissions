kubectl -n k8smissions get endpoints catalog
kubectl -n k8smissions logs deploy/catalog --tail=3
kubectl -n k8smissions patch deployment catalog --type=json -p '[{"op":"add","path":"/spec/template/spec/containers/0/readinessProbe","value":{"httpGet":{"path":"/ready","port":8080},"periodSeconds":2}}]'
kubectl -n k8smissions rollout status deployment/catalog --timeout=120s

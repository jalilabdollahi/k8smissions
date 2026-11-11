kubectl -n k8smissions get endpoints thumb-api
kubectl -n k8smissions logs deploy/thumb-api
kubectl -n k8smissions describe service thumb-api
kubectl -n k8smissions patch service thumb-api --type=json -p '[{"op":"replace","path":"/spec/ports/0/targetPort","value":5678}]'

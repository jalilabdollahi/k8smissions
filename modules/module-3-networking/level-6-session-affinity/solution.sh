kubectl -n k8smissions get svc portal -o yaml
kubectl -n k8smissions patch service portal -p '{"spec":{"sessionAffinity":"ClientIP"}}'

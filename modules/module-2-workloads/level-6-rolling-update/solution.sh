kubectl -n k8smissions get deployment critical-api -o jsonpath='{.spec.strategy}{"\n"}'
kubectl explain deployment.spec.strategy
kubectl -n k8smissions patch deployment critical-api -p '{"spec":{"strategy":{"type":"RollingUpdate"}}}'

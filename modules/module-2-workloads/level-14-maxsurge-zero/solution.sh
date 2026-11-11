kubectl -n k8smissions get deployment api-server -o jsonpath='{.spec.strategy}{"\n"}'
kubectl -n k8smissions patch deployment api-server --type=merge -p '{"spec":{"strategy":{"rollingUpdate":{"maxSurge":0,"maxUnavailable":1}}}}'
kubectl -n k8smissions rollout status deployment/api-server --timeout=120s

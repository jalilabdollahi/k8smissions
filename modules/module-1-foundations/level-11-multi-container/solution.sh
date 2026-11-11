kubectl -n k8smissions get pods -l app=checkout
POD=$(kubectl -n k8smissions get pods -l app=checkout -o name | head -1)
kubectl -n k8smissions logs $POD -c log-shipper
kubectl -n k8smissions get deployment checkout -o jsonpath='{.spec.template.spec.volumes[*].name}'
kubectl -n k8smissions patch deployment checkout -p '{"spec":{"template":{"spec":{"containers":[{"name":"log-shipper","volumeMounts":[{"name":"logs","mountPath":"/logs"}]}]}}}}'
kubectl -n k8smissions rollout status deployment/checkout --timeout=80s

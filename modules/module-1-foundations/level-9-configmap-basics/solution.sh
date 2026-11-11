kubectl -n k8smissions get configmap pricing-config -o jsonpath='{.data}{"\n"}'
kubectl -n k8smissions exec deploy/pricing -- env | grep TAX_RATE
kubectl -n k8smissions rollout restart deployment/pricing
kubectl -n k8smissions rollout status deployment/pricing --timeout=90s

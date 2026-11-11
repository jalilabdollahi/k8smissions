kubectl -n k8smissions get pods
kubectl -n k8smissions get events --field-selector reason=Evicted | tail -3
kubectl -n k8smissions get limitrange container-defaults -o yaml | sed -n '/spec/,$p'
kubectl -n k8smissions set resources deploy/log-compactor --limits=ephemeral-storage=300Mi --requests=ephemeral-storage=200Mi
kubectl -n k8smissions rollout status deploy/log-compactor --timeout=120s
kubectl -n k8smissions get pods

kubectl -n k8smissions get pods
kubectl -n k8smissions get pods --field-selector=status.phase=Failed -o jsonpath='{.items[0].status.message}{"\n"}'
kubectl describe nodes | grep -A6 'Conditions:'
kubectl -n k8smissions logs deploy/audit-spooler --tail=2
kubectl -n k8smissions set env deploy/audit-spooler SPOOL_KEEP=3
kubectl -n k8smissions rollout status deploy/audit-spooler --timeout=100s
kubectl -n k8smissions delete pod --field-selector=status.phase=Failed

kubectl -n k8smissions describe pod -l app=payments-migrator | tail -6
kubectl -n k8smissions get pod -l app=payments-migrator -o jsonpath='{range .items[0].spec.initContainers[*]}{.name}{" "}{.resources}{"\n"}{end}'
kubectl describe node | grep -A8 'Allocated resources'
kubectl -n k8smissions patch deploy payments-migrator --type=json -p '[
 {"op":"replace","path":"/spec/template/spec/initContainers/0/resources/requests/memory","value":"700Mi"}]'
kubectl -n k8smissions rollout status deploy/payments-migrator --timeout=150s
kubectl -n k8smissions logs deploy/payments-migrator -c db-migrate

kubectl -n k8smissions describe pod -l app=etl-runner | grep -A3 Events
kubectl get node -l pool=etl -o jsonpath='{.items[0].spec.taints}'
kubectl -n k8smissions patch deployment etl-runner -p '{"spec":{"template":{"spec":{"tolerations":[{"key":"dedicated","operator":"Equal","value":"etl","effect":"NoSchedule"},{"key":"team","operator":"Equal","value":"data","effect":"NoSchedule"}]}}}}'
kubectl -n k8smissions rollout status deploy/etl-runner --timeout=80s

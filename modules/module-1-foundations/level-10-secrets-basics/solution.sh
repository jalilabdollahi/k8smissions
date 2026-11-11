kubectl -n k8smissions describe pod -l app=reports-api | grep -i -A2 'Error'
kubectl -n k8smissions get secret reports-db -o jsonpath='{.data}{"\n"}'
kubectl -n k8smissions patch deployment reports-api --type=json -p '[{"op":"replace","path":"/spec/template/spec/containers/0/env/0/valueFrom/secretKeyRef/key","value":"db-password"}]'
kubectl -n k8smissions rollout status deployment/reports-api --timeout=90s

POD=$(kubectl -n k8smissions get pods -l app=rates-sync -o name | head -1)
kubectl -n k8smissions logs $POD --previous | grep ERROR
kubectl -n k8smissions get configmap rates-sync-conf -o jsonpath='{.data.rates\.conf}' | cat -n | sed -n 7p
kubectl -n k8smissions get configmap rates-sync-conf -o yaml | sed 's/refresh_interval = 5min/refresh_interval = 5m/' | kubectl apply -f -
kubectl -n k8smissions delete pod -l app=rates-sync
sleep 5
POD=$(kubectl -n k8smissions get pods -l app=rates-sync -o name | head -1)
kubectl -n k8smissions logs $POD --previous | grep ERROR || kubectl -n k8smissions logs $POD | grep ERROR
kubectl -n k8smissions get configmap rates-sync-conf -o yaml | sed 's/region = eu-west-9/region = eu-central-1/' | kubectl apply -f -
kubectl -n k8smissions delete pod -l app=rates-sync
kubectl -n k8smissions rollout status deployment/rates-sync --timeout=100s

kubectl -n k8smissions exec deploy/prom-lite -- wget -qO- http://localhost:9090/targets
kubectl -n k8smissions get pod -l app=payments-api -o jsonpath='{.items[0].metadata.annotations}'
kubectl -n k8smissions logs deploy/payments-api | head -2
kubectl -n k8smissions patch deploy payments-api --type=merge -p '{"spec":{"template":{"metadata":{"annotations":{"prometheus.io/scrape":"true","prometheus.io/port":"9102","prometheus.io/path":"/metrics"}}}}}'
kubectl -n k8smissions rollout status deploy/payments-api --timeout=90s

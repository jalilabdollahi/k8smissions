kubectl -n k8smissions get pods -l app=rates-proxy
POD=$(kubectl -n k8smissions get pods -l app=rates-proxy -o name | head -1)
kubectl -n k8smissions logs $POD -c edge
kubectl -n k8smissions patch deployment rates-proxy --type=json -p '[{"op":"replace","path":"/spec/template/spec/containers/0/command/2","value":"mkdir -p /srv/www\necho \"rates: EUR/USD 1.08\" > /srv/www/index.html\nexec python -m http.server 8080 --directory /srv/www\n"}]'
kubectl -n k8smissions rollout status deployment/rates-proxy --timeout=90s

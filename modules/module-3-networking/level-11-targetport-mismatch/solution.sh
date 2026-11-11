kubectl -n k8smissions get endpointslices -l kubernetes.io/service-name=checkout -o yaml
kubectl -n k8smissions get pods -l app=checkout -o jsonpath='{.items[0].spec.containers[0].ports}'
kubectl -n k8smissions get svc checkout -o jsonpath='{.spec.ports}'
kubectl -n k8smissions patch svc checkout --type=json -p '[{"op":"replace","path":"/spec/ports/0/targetPort","value":"app-http"}]'

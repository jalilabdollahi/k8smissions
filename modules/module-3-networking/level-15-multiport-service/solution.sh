kubectl -n k8smissions describe ingress gateway
kubectl -n k8smissions get svc gateway -o yaml
kubectl -n k8smissions patch ingress gateway --type=json -p '[{"op":"replace","path":"/spec/rules/0/http/paths/0/backend/service/port","value":{"name":"http"}}]'
kubectl -n k8smissions patch svc gateway --type=json -p '[{"op":"replace","path":"/spec/ports/1/protocol","value":"TCP"}]'

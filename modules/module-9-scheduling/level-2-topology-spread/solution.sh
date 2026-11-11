kubectl -n k8smissions get pods -o wide --show-labels
kubectl -n k8smissions get deploy catalog-api -o jsonpath='{.spec.template.spec.topologySpreadConstraints}'
kubectl -n k8smissions patch deploy catalog-api --type=json -p '[{"op":"replace","path":"/spec/template/spec/topologySpreadConstraints/0/labelSelector/matchLabels","value":{"app.kubernetes.io/name":"catalog-api"}}]'
kubectl -n k8smissions rollout status deploy/catalog-api --timeout=120s
kubectl -n k8smissions get pods -o wide

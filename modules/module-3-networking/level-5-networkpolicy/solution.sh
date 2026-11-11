kubectl -n k8smissions get networkpolicy
kubectl -n k8smissions get pods --show-labels
kubectl -n k8smissions patch networkpolicy allow-frontend --type=json -p '[{"op":"replace","path":"/spec/ingress/0/from/0/podSelector/matchLabels","value":{"app":"storefront"}},{"op":"replace","path":"/spec/ingress/0/ports/0/port","value":8080}]'

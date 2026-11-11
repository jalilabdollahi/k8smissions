The allow rule has two mistakes: it admits pods labelled `role=frontend` (the storefront pods are `app=storefront`) and it opens port 80 (ledger-api listens on 8080).

1. `kubectl -n k8smissions describe networkpolicy allow-frontend` shows the peer selector and port.
2. `kubectl -n k8smissions get pods --show-labels` shows the storefront pods' real labels.
3. Patch the policy: `kubectl -n k8smissions patch networkpolicy allow-frontend --type=json -p '[{"op":"replace","path":"/spec/ingress/0/from/0/podSelector/matchLabels","value":{"app":"storefront"}},{"op":"replace","path":"/spec/ingress/0/ports/0/port","value":8080}]'`.

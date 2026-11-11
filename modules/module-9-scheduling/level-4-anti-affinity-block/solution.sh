kubectl -n k8smissions get pods -o wide
kubectl -n k8smissions describe pod -l app=ledger-api | grep -A3 FailedScheduling
kubectl -n k8smissions get deploy ledger-api -o jsonpath='{.spec.template.spec.affinity}'
kubectl -n k8smissions patch deploy ledger-api --type=json -p '[{"op":"replace","path":"/spec/template/spec/affinity/podAntiAffinity","value":{"preferredDuringSchedulingIgnoredDuringExecution":[{"weight":100,"podAffinityTerm":{"labelSelector":{"matchLabels":{"app":"ledger-api"}},"topologyKey":"kubernetes.io/hostname"}}]}}]'
kubectl -n k8smissions rollout status deploy/ledger-api --timeout=120s
kubectl -n k8smissions get pods -o wide

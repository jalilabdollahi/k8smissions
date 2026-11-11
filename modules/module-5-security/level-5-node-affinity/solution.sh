kubectl get nodes -L data-class
kubectl -n k8smissions get pods -l app=ledger-api -o wide
kubectl -n k8smissions patch deployment ledger-api --type=json -p '[{"op":"replace","path":"/spec/template/spec/affinity/nodeAffinity","value":{"requiredDuringSchedulingIgnoredDuringExecution":{"nodeSelectorTerms":[{"matchExpressions":[{"key":"data-class","operator":"In","values":["restricted"]}]}]}}}]'
kubectl -n k8smissions rollout status deploy/ledger-api --timeout=100s

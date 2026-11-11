kubectl -n k8smissions get svc audit-gw -o yaml
kubectl -n k8smissions get pods -l app=audit-gw -o wide
kubectl -n k8smissions get deploy audit-gw -o jsonpath='{.spec.template.spec.affinity}'
kubectl -n k8smissions patch deploy audit-gw --type=json -p '[{"op":"remove","path":"/spec/template/spec/affinity"},{"op":"add","path":"/spec/template/spec/topologySpreadConstraints","value":[{"maxSkew":1,"topologyKey":"kubernetes.io/hostname","whenUnsatisfiable":"DoNotSchedule","labelSelector":{"matchLabels":{"app":"audit-gw"}}}]}]'
kubectl -n k8smissions rollout status deploy/audit-gw --timeout=120s
kubectl -n k8smissions get pods -l app=audit-gw -o wide

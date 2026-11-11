kubectl -n k8smissions get ds host-audit
kubectl -n k8smissions get pods -o wide
kubectl get nodes
kubectl describe node -l node-role.kubernetes.io/control-plane | grep -i taints
kubectl -n k8smissions patch daemonset host-audit --type=json -p '[{"op":"add","path":"/spec/template/spec/tolerations","value":[{"key":"node-role.kubernetes.io/control-plane","operator":"Exists","effect":"NoSchedule"}]}]'
kubectl -n k8smissions rollout status daemonset/host-audit --timeout=80s

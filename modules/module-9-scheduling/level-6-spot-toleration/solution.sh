kubectl -n k8smissions get pods -o wide
kubectl -n k8smissions describe pod -l app=render-farm | grep -A4 Events
kubectl get nodes -L lifecycle
kubectl describe nodes | grep -E "^Name:|^Taints:"
kubectl -n k8smissions patch deploy render-farm --type=json -p '[{"op":"remove","path":"/spec/template/spec/nodeSelector"},{"op":"add","path":"/spec/template/spec/tolerations","value":[{"key":"lifecycle","operator":"Equal","value":"on-demand","effect":"NoSchedule"}]}]'
kubectl -n k8smissions rollout status deploy/render-farm --timeout=120s
kubectl -n k8smissions get pods -o wide

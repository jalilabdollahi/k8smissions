kubectl -n k8smissions get pods -o wide
kubectl -n k8smissions describe pod -l tier=frontend | grep -A1 FailedScheduling | head -4
kubectl get nodes -L zone
kubectl label node "$(kubectl get nodes -l '!node-role.kubernetes.io/control-plane,!zone' -o jsonpath='{.items[0].metadata.name}')" zone=zone-b
kubectl -n k8smissions describe pod -l tier=cart | grep -A1 FailedScheduling | head -4
kubectl -n k8smissions patch deploy shop-cart --type=json -p '[{"op":"replace","path":"/spec/template/spec/affinity/podAntiAffinity/requiredDuringSchedulingIgnoredDuringExecution/0/labelSelector/matchLabels","value":{"app":"shop","tier":"cart"}}]'
kubectl -n k8smissions describe pod -l app=shop-agent | grep -A1 FailedScheduling | head -4
kubectl get pods -A -o wide | grep 8125
kubectl -n k8smissions get pod statsd-debug -o yaml | grep -E 'owner|note|hostPort'
kubectl -n k8smissions delete pod statsd-debug
kubectl -n k8smissions rollout status deploy/shop-frontend --timeout=120s
kubectl -n k8smissions rollout status deploy/shop-cart --timeout=120s
kubectl -n k8smissions rollout status deploy/shop-agent --timeout=120s
kubectl -n k8smissions get pods -o wide

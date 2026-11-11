kubectl top nodes
kubectl -n k8smissions describe pod -l app=checkout | grep -A2 FailedScheduling | head -4
kubectl describe node | grep -A8 'Allocated resources'
kubectl get priorityclass
kubectl apply -f - <<'YAML'
apiVersion: scheduling.k8s.io/v1
kind: PriorityClass
metadata:
  name: overprovisioning
value: -10
globalDefault: false
description: "placeholder pods that yield to real workloads"
YAML
kubectl -n k8smissions patch deploy capacity-reserve --type=merge -p '{"spec":{"template":{"spec":{"priorityClassName":"overprovisioning"}}}}'
kubectl -n k8smissions rollout status deploy/checkout --timeout=150s
kubectl -n k8smissions get pods -o wide

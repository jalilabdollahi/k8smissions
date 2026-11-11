kubectl -n k8smissions describe pod -l app=checkout
kubectl get priorityclass
kubectl get priorityclass platform-critical -o yaml
kubectl apply -f - <<'YAML'
apiVersion: scheduling.k8s.io/v1
kind: PriorityClass
metadata:
  name: checkout-critical
value: 100000
preemptionPolicy: PreemptLowerPriority
globalDefault: false
description: "Customer-facing platform services."
YAML
kubectl -n k8smissions patch deploy checkout --type=merge -p '{"spec":{"template":{"spec":{"priorityClassName":"checkout-critical"}}}}'
kubectl -n k8smissions rollout status deploy/checkout --timeout=90s

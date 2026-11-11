kubectl -n k8smissions get pods -o wide
kubectl -n k8smissions describe pod -l app=pay-gateway | grep -A4 Events
kubectl get priorityclass
kubectl get priorityclass payments-high -o yaml
kubectl apply -f - <<'YAML'
apiVersion: scheduling.k8s.io/v1
kind: PriorityClass
metadata:
  name: payments-critical
value: 100000
preemptionPolicy: PreemptLowerPriority
description: "payments production workloads, may preempt"
YAML
kubectl -n k8smissions patch deploy pay-gateway -p '{"spec":{"template":{"spec":{"priorityClassName":"payments-critical"}}}}'
kubectl -n k8smissions rollout status deploy/pay-gateway --timeout=120s
kubectl -n k8smissions get events --field-selector reason=Preempted

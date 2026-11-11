**Fix**

1. `kubectl -n k8smissions describe pod -l app=checkout` shows `Insufficient cpu` and no preemption attempt.
2. `kubectl get priorityclass platform-critical -o yaml` shows `preemptionPolicy: Never`: the pods outrank batch work in the queue but never evict it.
3. The field is immutable, so create a new class:
   `kubectl apply -f -` with `kind: PriorityClass`, `name: checkout-critical`, `value: 100000`, `preemptionPolicy: PreemptLowerPriority`.
4. `kubectl -n k8smissions patch deploy checkout --type=merge -p '{"spec":{"template":{"spec":{"priorityClassName":"checkout-critical"}}}}'`.

The scheduler now evicts `batch-reindex` pods to fit `checkout`. Do not scale the batch Deployment down by hand and do not make a class `globalDefault`.

1. `kubectl get priorityclass payments-high -o yaml` shows `value: 100000` but `preemptionPolicy: Never`: the pods may jump the queue but never evict anyone.
2. Class fields are immutable, so create a new class that allows preemption:
   `kubectl apply -f -` with `kind: PriorityClass`, `name: payments-critical`, `value: 100000`, `preemptionPolicy: PreemptLowerPriority`.
3. Point the Deployment at it (this rolls the pods, and new pods get the new policy):
   `kubectl -n k8smissions patch deploy pay-gateway -p '{"spec":{"template":{"spec":{"priorityClassName":"payments-critical"}}}}'`
4. The scheduler now evicts two `dev-sandbox` pods (`kubectl get events --field-selector reason=Preempted`) and the gateway starts.

1. `kubectl top nodes` shows under 10% CPU, but `describe node` shows requests near 100%: the 6 `capacity-reserve` pause pods request most of the CPU.
2. Placeholder and checkout pods both have priority 0, so no preemption can happen. Create a negative priority class and put the placeholders in it:
   `kubectl apply -f -` with `kind: PriorityClass`, `name: overprovisioning`, `value: -10`
   `kubectl -n k8smissions patch deploy capacity-reserve --type=merge -p '{"spec":{"template":{"spec":{"priorityClassName":"overprovisioning"}}}}'`
3. The placeholder Deployment uses `Recreate`, so all its pods are replaced at priority -10. The Pending `checkout` pods now outrank them: they are scheduled first (and would preempt placeholders if needed), and the remaining placeholders stay as headroom.

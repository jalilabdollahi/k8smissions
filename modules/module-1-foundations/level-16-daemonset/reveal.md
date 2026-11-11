1. `kubectl get pods -o wide` shows agents on the two workers only; `kubectl describe node` on the control plane shows `Taints: node-role.kubernetes.io/control-plane:NoSchedule`.
2. The DaemonSet pod template has no toleration, so the controller does not create a pod for that node at all (hence no Pending pod and DESIRED 2).
3. Add a toleration for `node-role.kubernetes.io/control-plane` with `operator: Exists` and `effect: NoSchedule` to `spec.template.spec.tolerations`.
4. Do not remove the taint; the node reset would put it back and it protects other workloads.

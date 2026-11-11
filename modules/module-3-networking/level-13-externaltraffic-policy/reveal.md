1. Both `audit-gw` pods run on the same worker, held together by a `podAffinity` rule on the hostname. With `externalTrafficPolicy: Local`, the other worker has no local endpoint and drops NodePort traffic.
2. Switching the Service to `Cluster` makes both nodes answer, but kube-proxy then masquerades the source, and the audit log records node addresses. Keep `Local`.
3. Replace the affinity with a topology spread constraint so one pod lands on each worker:

   `kubectl -n k8smissions patch deploy audit-gw --type=json -p '[{"op":"remove","path":"/spec/template/spec/affinity"},{"op":"add","path":"/spec/template/spec/topologySpreadConstraints","value":[{"maxSkew":1,"topologyKey":"kubernetes.io/hostname","whenUnsatisfiable":"DoNotSchedule","labelSelector":{"matchLabels":{"app":"audit-gw"}}}]}]'`

4. Wait for the rollout; both workers now answer with the real caller address.

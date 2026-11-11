1. `kubectl -n k8smissions get deploy,pods,svc -l app=ledger-db` shows a Deployment with random pod names and a headless Service (`clusterIP: None`) called `ledger-db`.
2. Export the container spec: `kubectl -n k8smissions get deploy ledger-db -o yaml`.
3. `kubectl -n k8smissions delete deployment ledger-db` removes the random pods that also match the Service.
4. Apply a StatefulSet named `ledger-db` with `serviceName: ledger-db`, 3 replicas, the same selector, labels and container.
5. `kubectl -n k8smissions rollout status statefulset/ledger-db` waits for `ledger-db-0..2`; each is reachable at `<pod>.ledger-db`.

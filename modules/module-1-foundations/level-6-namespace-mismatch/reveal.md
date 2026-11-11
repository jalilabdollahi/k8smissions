1. `kubectl get deploy,svc,cm -A` shows `orders-api` (Deployment, Service, ConfigMap) in namespace `orders-staging`, not `k8smissions`.
2. A teammate's `kubectl apply` ran against the wrong namespace (see ConfigMap `deploy-log`).
3. `kubectl -n k8smissions set env deployment/orders-web UPSTREAM=http://orders-api.orders-staging.svc.cluster.local` makes the existing backend reachable; the rollout restarts `orders-web`.
4. Alternatively recreate Deployment, Service and ConfigMap `orders-api` in `k8smissions` (all three, otherwise the pod hangs in `ContainerCreating`).

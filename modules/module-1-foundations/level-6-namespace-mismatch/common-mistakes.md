## Common mistakes

- **Searching only the current namespace.** `kubectl get pods` is empty for objects that live elsewhere; use `-A` or look at `kubectl get ns`.
- **Moving the Deployment and Service but not the ConfigMap.** The pod mounts ConfigMap `orders-api`; without it in the same namespace it sits in `ContainerCreating`.
- **Applying the exported YAML unchanged.** The objects still say `namespace: orders-staging`, so `kubectl apply -n k8smissions` refuses it. Strip the namespace field (and status and uid fields) first.
- **Using the pod IP of the staging backend.** It works once, then breaks on the next restart. Use the Service name.

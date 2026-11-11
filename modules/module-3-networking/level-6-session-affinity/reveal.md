The three pods keep sessions in their own memory, and the Service spreads requests across all of them, so most requests land on a pod that never saw the login.

1. `kubectl -n k8smissions get svc portal -o yaml` shows `sessionAffinity: None`.
2. `kubectl -n k8smissions patch service portal -p '{"spec":{"sessionAffinity":"ClientIP"}}'` makes kube-proxy send each client IP to the same pod.
3. Keep 3 replicas: scaling down to one would hide the problem instead of fixing it.

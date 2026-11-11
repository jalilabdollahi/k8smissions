**Fix**

1. `kubectl -n k8smissions describe rs -l app=invoice-api`: `failed quota: team-quota: must specify limits.cpu,limits.memory`.
2. The quota caps `limits.*` for the namespace, so each pod must declare limits, and 3 pods together must stay at or under 2 CPU / 2Gi.
3. `kubectl -n k8smissions set resources deployment invoice-api --limits=cpu=500m,memory=512Mi` (any values up to about 600m / 640Mi per pod fit).
4. The Deployment rolls out and the ReplicaSet creates the 3 pods.

Alternative on the platform side: a `LimitRange` with `default` limits in the namespace gives containers limits automatically.

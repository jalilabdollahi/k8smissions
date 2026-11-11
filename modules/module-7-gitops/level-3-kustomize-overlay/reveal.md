The production overlay (`namePrefix: prod-`) was applied to `shop-staging`. Its 4 pods use the whole `staging-pods` quota (4), so the `stg-` ReplicaSet cannot create pods.

1. `kubectl -n shop-staging get all,hpa,pdb,resourcequota` and `get events` show `prod-checkout`, its HPA and PDB, and "exceeded quota" on `stg-checkout`.
2. Clone the repo through a port-forward to the Git server and run `kubectl kustomize overlays/production` to list what that overlay creates.
3. `kubectl delete -k overlays/production -n shop-staging` removes exactly those objects. Careful with `-n`: `shop-prod` runs the same overlay for real.
4. Once the quota is free, the ReplicaSet creates the `stg-` pods (`kubectl -n shop-staging rollout status deploy/stg-checkout`).

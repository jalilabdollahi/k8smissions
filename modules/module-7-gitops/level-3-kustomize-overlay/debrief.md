**What was broken.** `kubectl apply -k overlays/production` targeted the staging namespace. Because the overlay prefixes names (`prod-checkout`, `prod-checkout` HPA and PDB), the later staging apply did not replace anything, it added `stg-checkout` beside them. The 4 production pods consumed the namespace's pod quota, so the `stg-` ReplicaSet kept failing with "exceeded quota".

**The evidence.** `kubectl -n shop-staging get all,hpa,pdb` listed objects with a prefix that does not belong, `get resourcequota` showed 4 of 4 pods used, and the events on the staging ReplicaSet said `FailedCreate ... exceeded quota`.

**Why Kubernetes behaved this way.** `kubectl apply` only creates or updates the objects it is given; it never removes objects that were applied from a different set of manifests. Kustomize `namePrefix` makes each overlay a different set of names, so overlays do not overwrite each other. Quotas are enforced at admission, so pods that do not fit are not created at all.

**The fix.** Delete the set the wrong overlay created, in the right namespace: `kubectl delete -k overlays/production -n shop-staging`. The kustomization defines exactly what to remove, which is safer than deleting by guess. The ReplicaSet then retries and the `stg-` pods start. `shop-prod` runs the same overlay, so the namespace flag decides which set you delete.

**In production.** Pin the namespace in the overlay (`namespace:` in kustomization.yaml) or use one cluster context per environment, and let a GitOps controller with pruning own the set, so a wrong apply is reverted instead of accumulating.

**Commands worth remembering.**
- `kubectl kustomize DIR` to preview, `kubectl get -k DIR -n NS` to see what exists
- `kubectl diff -k DIR -n NS`
- `kubectl delete -k DIR -n NS`

# Common mistakes: level 1

**Fixing the Pending claim.** `orders-data` is Pending because nothing uses it yet. Deleting it, resizing it or hunting for a PersistentVolume for it changes nothing: the pod does not reference it. Read the pod's events first and fix the object the pod names.

**Deleting the Deployment's pod or restarting the rollout.** A new pod asks for the same missing claim and goes Pending again. Restarts only help when the cause is inside the container.

**Creating a claim with a similar but wrong name.** `orders-db-claim` or `orders-data-db` will not satisfy the volume. The name must match `claimName` exactly, in the same namespace as the pod. Copy it from `kubectl get deployment orders-db -o yaml`.

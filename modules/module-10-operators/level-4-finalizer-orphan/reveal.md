In the operator's delete branch, `release(ds)` removes the finalizer first. The API server then deletes the Datastore at once, and the following `cleanup(name)` looks the Datastore up again to read the backend name from its annotation, gets a 404 and logs "nothing to clean up". Do the cleanup first and release last, and clean up the leftovers of `legacy-orders` by hand, since no code runs for objects that are already gone:

```bash
kubectl -n k8smissions edit configmap datastore-operator-code     # call cleanup(name) before release(ds)
kubectl -n k8smissions rollout restart deployment/datastore-operator
kubectl -n k8smissions delete pod/ds-legacy-orders configmap/ds-legacy-orders
```

Setting an `ownerReference` from the backend Pod and ConfigMap to the Datastore when creating them would also work (the garbage collector removes dependants), but only for backends created after the change.

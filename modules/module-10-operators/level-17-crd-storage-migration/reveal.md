The CRD's storage version is still `v1alpha1`, so `status.storedVersions` is `["v1alpha1"]` and the API server rejects the final CRD that no longer lists it. Migrate in this order:

```bash
# 1. make v1 the storage version (both stay served for now)
kubectl patch crd configs.settings.acme.io --type=json -p '[{"op":"replace","path":"/spec/versions/0/storage","value":false},{"op":"replace","path":"/spec/versions/1/storage","value":true}]'
# 2. rewrite the 30 objects: a write stores them in the new storage version
kubectl get configs.v1.settings.acme.io -A -o json | kubectl replace -f -
# 3. nothing is stored as v1alpha1 anymore: say so
kubectl patch crd configs.settings.acme.io --subresource=status --type=merge -p '{"status":{"storedVersions":["v1"]}}'
```

`crd-sync` retries every 5 seconds and then removes `v1alpha1` from `spec.versions`. If you patch `storedVersions` before rewriting the objects, the Job succeeds, but the objects are still encoded as v1alpha1 in etcd and every read fails with `request to convert CR from an invalid group/version`.

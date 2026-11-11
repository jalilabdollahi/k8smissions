## What was broken

The `Config` CRD still had `v1alpha1` as its storage version, so all 30 objects were stored in etcd as `v1alpha1` and `status.storedVersions` said so. The Job that rolls out the final CRD removes `v1alpha1` from `spec.versions`, and the API server rejects exactly that change.

## The evidence

The Job's log quoted the API server: `status.storedVersions[0]: Invalid value: "v1alpha1": missing from spec.versions; v1alpha1 was previously a storage version, and must remain in spec.versions until a storage migration ensures no data remains persisted in v1alpha1`. `kubectl get crd ... -o yaml` showed `storage: true` on `v1alpha1` and `storedVersions: [v1alpha1]`.

## Why Kubernetes behaved this way

The API server never rewrites stored objects by itself when you change the storage version; existing objects stay as written until something writes them again. `storedVersions` is the safety record: it lists every version that might still be in etcd. It only grows automatically, and you may remove a version only after a storage migration. Removing it earlier, by editing the status, makes the API unable to decode objects still stored in that version: reads then fail with `request to convert CR from an invalid group/version`, and the data is stuck.

A migration is therefore: set the new storage version, rewrite all objects (an empty update is enough, since the stored bytes differ), then shrink `storedVersions`, and only then drop the old version from `spec.versions`.

## In production

The Kube Storage Version Migrator or a small Job doing `kubectl get ... -o json | kubectl replace -f -` per namespace does the rewrite. Do it with a backup, and keep serving the old version until clients have moved. Conversion webhooks are needed when the schema, not only the version name, differs.

## Worth remembering

- `kubectl get crd <name> -o jsonpath='{.status.storedVersions}'`
- `kubectl patch crd <name> --subresource=status --type=merge -p '{"status":{"storedVersions":["v1"]}}'`
- `kubectl get <kind>.<version>.<group> -A -o json | kubectl replace -f -`

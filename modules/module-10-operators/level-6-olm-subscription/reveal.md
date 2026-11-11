The bundles form a chain: 1.4.0 `replaces` 1.3.0, which `replaces` 1.2.0. Release 1.3.0 is the migration release: it moves every Widget to the new schema (`spec.sizing.replicas`, `status.schemaVersion: 2`). Release 1.4.0 refuses to start (and crash-loops) while any Widget is still on the old schema, so installing it directly on top of 1.2.0 does not work.

```bash
# step 1: install 1.3.0 and let it migrate gauge, dial and meter
kubectl -n k8smissions patch deployment widget-operator --type=json -p '[{"op":"replace","path":"/spec/template/spec/volumes/0/configMap/name","value":"bundle-1.3.0"}]'
kubectl -n k8smissions rollout status deployment/widget-operator
kubectl -n k8smissions get widgets -o custom-columns=NAME:.metadata.name,SCHEMA:.status.schemaVersion   # all 2

# step 2: install 1.4.0
kubectl -n k8smissions patch deployment widget-operator --type=json -p '[{"op":"replace","path":"/spec/template/spec/volumes/0/configMap/name","value":"bundle-1.4.0"}]'
kubectl -n k8smissions rollout status deployment/widget-operator
```

Updating the `olm.acme.io/pinned-version` label is good housekeeping but changes nothing by itself: the volume decides what runs.

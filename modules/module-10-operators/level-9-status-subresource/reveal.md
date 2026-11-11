Two linked faults:

1. The `Backup` CRD has no `status` subresource, so `PATCH .../backups/<name>/status`, which `backup-operator` uses, does not exist and returns 404. Enable it:

```bash
kubectl patch crd backups.backup.acme.io --type=json -p '[{"op":"add","path":"/spec/versions/0/subresources","value":{"status":{}}}]'
```

2. The moment the subresource is on, a patch to the main resource silently ignores `status` (the call still returns 200). `sla-reporter` writes `lastSlaCheck` through the main endpoint, so it stops working without an error. Change its script to patch `.../backups/<name>/status`:

```bash
kubectl -n k8smissions edit configmap sla-reporter-code      # patch(BASE + "/" + name + "/status", ...)
kubectl -n k8smissions create job sla-test --from=cronjob/sla-reporter
```

New Jobs read the ConfigMap when their pod starts, so no restart is needed. With the subresource in place, status writes no longer bump `metadata.generation`.

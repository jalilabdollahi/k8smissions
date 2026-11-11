The namespace holds 100 ConfigMaps, the quota's hard limit: 96 old `export-result-*` results plus a few real ones. The exporter writes its results with `app=exporter` but deletes old results by `app=exporter-output`, so nothing ever matches and one ConfigMap is left behind on every run.

1. `kubectl describe resourcequota object-counts` shows `count/configmaps 100/100`; `kubectl get cm --show-labels` shows the pile of `export-result-*` with `app=exporter`.
2. `kubectl get cm exporter-script -o yaml` shows the label mismatch. Make new results carry `app: exporter-output` (edit the script), so each run replaces the previous one.
3. Delete the old results, but not the one `billing-web` mounts: `kubectl delete cm -l app=exporter --field-selector=metadata.name!=export-result-0042`.
4. Check with `kubectl create job --from=cronjob/exporter test-run` twice: the count stays flat.

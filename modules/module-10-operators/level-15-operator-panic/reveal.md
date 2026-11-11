Two causes, one after the other:

1. The release skipped `crds/`, so `GET .../workloads` returns 404, the response has no `items`, and the loop over `None` raises `TypeError` (the script has no error handling and exits). Install what the release was missing, CRD first and then the Workloads:

```bash
kubectl -n k8smissions get cm release-manifests -o jsonpath='{.data.crds\.yaml}' | kubectl apply -f -
kubectl wait --for=condition=Established crd/workloads.platform.acme.io
kubectl -n k8smissions get cm release-manifests -o jsonpath='{.data.workloads\.yaml}' | kubectl apply -f -
```

2. `legacy-sync` has no `spec.options`, so `options` is `None` and `options["retries"]` raises `TypeError: 'NoneType' object is not subscriptable`. Make the controller tolerate it (`options = ... or {}` and `options.get("retries", 1)`) by editing ConfigMap `workload-operator-code`, then restart:

```bash
kubectl -n k8smissions rollout restart deploy/workload-operator
```

`kubectl get all` expands to the resources whose CRD lists the category `all`; a short name comes from `spec.names.shortNames`; extra columns come from `additionalPrinterColumns`. The CRD had none of the three. Add them without touching the stored objects:

```bash
kubectl patch crd invoicebatches.billing.acme.io --type=json -p '[
  {"op":"add","path":"/spec/names/categories","value":["all"]},
  {"op":"add","path":"/spec/names/shortNames","value":["ib"]},
  {"op":"add","path":"/spec/versions/0/additionalPrinterColumns","value":[
    {"name":"State","type":"string","jsonPath":".status.state"},
    {"name":"Progress","type":"string","jsonPath":".status.progress"}]}
]'
```

kubectl caches discovery documents, so run `kubectl api-resources` (or wait a few minutes) if your own terminal still shows the old output.

kubectl -n k8smissions logs job/policy-sync --tail=3
kubectl patch crd backuppolicies.dba.acme.io --type=json -p '[
 {"op":"replace","path":"/spec/versions/0/schema/openAPIV3Schema/properties/spec/properties/retentionDays/minimum","value":1},
 {"op":"replace","path":"/spec/versions/0/schema/openAPIV3Schema/properties/spec/properties/schedule/pattern","value":"^(\\*|[0-9]+)(/[0-9]+)?( (\\*|[0-9]+)(/[0-9]+)?){4}$"}
]'
kubectl -n k8smissions wait --for=condition=complete job/policy-sync --timeout=90s

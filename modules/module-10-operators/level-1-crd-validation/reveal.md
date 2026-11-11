Two rules in the CRD schema reject the DBA's values:

1. `spec.retentionDays` has `minimum: 30`, but `nightly-db` keeps 14 days and `hourly-wal` keeps 7. Lower the minimum to a sane floor such as 1 (so 0 and negative numbers are still refused).
2. `spec.schedule` has a `pattern` that only allows `*` or plain numbers in each cron field, so `*/20 * * * *` fails. Extend each field to allow an optional step: `(\*|[0-9]+)(/[0-9]+)?`.

```bash
kubectl patch crd backuppolicies.dba.acme.io --type=json -p '[
 {"op":"replace","path":"/spec/versions/0/schema/openAPIV3Schema/properties/spec/properties/retentionDays/minimum","value":1},
 {"op":"replace","path":"/spec/versions/0/schema/openAPIV3Schema/properties/spec/properties/schedule/pattern","value":"^(\\*|[0-9]+)(/[0-9]+)?( (\\*|[0-9]+)(/[0-9]+)?){4}$"}
]'
```

The Job retries by itself and creates the three policies on its next pass. Do not edit the policies or the Job's data, and do not delete the schema: that would "fix" the Job and break the platform team's guard rails.

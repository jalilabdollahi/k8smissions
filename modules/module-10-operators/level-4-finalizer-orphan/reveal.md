## What went wrong

Finalizers implement pre-deletion hooks: the operator adds the finalizer when the CR is created, runs cleanup when deletion is requested, then removes the finalizer to unblock deletion. If the operator is deleted before it can clear the finalizer, the CR is stuck forever.

## Fix

```yaml
metadata:
  finalizers: []
```

Or via kubectl:
```bash
kubectl patch database prod-db -n k8smissions \
  --type=json \
  -p='[{"op":"remove","path":"/metadata/finalizers"}]'
```

## Why this matters

Finalizers are the mechanism operators use to clean up external resources (cloud databases, DNS records, S3 buckets) before the Kubernetes object is removed. The critical failure mode: uninstalling the operator without first deleting all its CRs leaves orphaned finalizers that prevent deletion forever. Best practice: always delete CRs before uninstalling an operator. Some operators support a `--delete-all` flag for this. If stuck, force-clearing finalizers works but leaves the external resources orphaned — manual cleanup is required.
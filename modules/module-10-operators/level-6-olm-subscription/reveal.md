## What went wrong

The OLM Subscription specifies `source: non-existent-catalog`. OLM searches this CatalogSource for the operator package and channel. With a nonexistent source, OLM cannot resolve any InstallPlan and the operator is never installed.

## Fix

```yaml
spec:
  channel: stable
  name: my-operator
  source: operatorhub
  sourceNamespace: olm
```

## Why this matters

OLM (Operator Lifecycle Manager) manages the lifecycle of operators in the cluster. The installation flow: CatalogSource (index of available operators) → Subscription (desire to install a specific operator from a channel) → InstallPlan (OLM-generated plan of what to create) → ClusterServiceVersion (the actual operator metadata and deployment). A missing CatalogSource silently stops the chain at step one. Always check `kubectl get catalogsource -n olm` to see what sources are available before writing a Subscription.
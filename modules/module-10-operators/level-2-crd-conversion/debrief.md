## What was broken

The `Cache` CRD serves two versions with different schemas (`v1alpha1` has `maxMemoryMB`, `v1` has `memory`) but its conversion strategy was `None`. With `None`, the API server converts between versions by changing only the `apiVersion` string, so a `v1` client sees the stored `v1alpha1` data with every renamed field missing. `cache-controller` then did exactly what its code says for an object with no `memory`: it used its 64Mi default.

## The evidence

Reading one object through both versions side by side shows the data is intact in `v1alpha1` and blank in `v1`. The CRD's `spec.conversion` is the only place that explains it. The converter was already running; it simply had no traffic (its logs stayed empty until the CRD was changed).

## Why Kubernetes behaved this way

Objects are stored in etcd in one storage version (here `v1alpha1`) and converted on every read or write in a different version. Conversion is the CRD author's responsibility, and the only non-trivial strategy is a webhook: the API server posts a `ConversionReview` over HTTPS to the service, verifies its certificate against `caBundle`, and trusts the converted objects it gets back. A wrong `caBundle` surfaces as an x509 error in `kubectl get`, a wrong `path` as a 404 in the converter's logs.

## In production

Run at least two converter replicas: while the webhook is down, every read of that CRD fails, controllers included. Keep conversions lossless in both directions (the validator's round trip) and never remove a version that has stored objects. Tools such as cert-manager inject `caBundle` for you.

## Worth remembering

- `kubectl get <kind>.<version>.<group> <name> -o yaml` reads through a specific version.
- `kubectl get crd <name> -o jsonpath='{.spec.conversion}'`
- `kubectl explain crd.spec.conversion.webhook.clientConfig`

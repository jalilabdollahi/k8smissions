## What was broken

The `Workload` CRD had no schema, only `x-kubernetes-preserve-unknown-fields: true`. The API server stores whatever it is given, so `replicas: -999` and `tier: gold-plated` were accepted and broke the tools that read them later. The API was doing no job as a contract.

## The evidence

`kubectl explain workload.spec` printed nothing useful (there are no fields to explain), and the CRD's `openAPIV3Schema` was one line. Applying a bad object succeeded, which for a typed API is already the finding.

## Why Kubernetes behaved this way

Schemas on CRDs must be structural, and the API server enforces them on every write. Two rules matter. Declared fields are validated: type, `enum`, `minimum`, `required`. Undeclared fields are pruned: dropped on write, and dropped when stored objects are read through the new schema. That is why the obvious fix, a schema with just `replicas` and `tier`, makes `owner` and `costCenter` vanish from the live Workloads, silently, without an error. The data may still be in etcd, but the API no longer returns it, and the first write would remove it for good.

## The fix

Describe every field that is in use (or mark `spec` with `x-kubernetes-preserve-unknown-fields: true` if the set is open), constrain the ones that must be constrained, then compare `kubectl get -o yaml` for the live objects with the copy you took before.

## In production

Treat a schema change as a migration: dump the existing objects first (`kubectl get workloads -A -o yaml`), apply with `--dry-run=server`, diff the result. Prefer CEL rules (`x-kubernetes-validations`) for cross-field constraints, and `kubectl explain` to prove the schema documents what you intended.

## Worth remembering

- `kubectl explain workload.spec --recursive`
- `kubectl create --dry-run=server -f obj.yaml`
- `kubectl get <kind> -A -o yaml > backup.yaml` before any schema change

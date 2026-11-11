## What was broken

A CRD's OpenAPI v3 schema is the API server's gatekeeper: every create and update of a custom resource is validated against it before it reaches etcd. Here the platform team's tightened schema disagreed with the DBA team's real data in two independent places: `retentionDays` had `minimum: 30` (the DBAs keep 14 and 7 days for two policies), and the `schedule` `pattern` had no room for step syntax such as `*/20`.

## The evidence

`kubectl logs job/policy-sync` quoted the API server's 422 message with the field, the value and the rule. The Job is deliberately all-or-nothing and stops at the first rejected policy, which is why fixing the first problem revealed the second one: one error message never tells you everything that is wrong with a set of objects.

## Why Kubernetes behaved this way

Schema validation is generic: the API server knows nothing about backups, only about types, ranges, enums and regular expressions. A rule that is too strict is rejected loudly, a rule that is missing is accepted silently, so the fix is to correct the rule, never to remove it. That is why the validator still probes with `retentionDays: 0`, a nonsense schedule and an unknown `tier`.

## In production

Schema changes are API changes. Tighten a schema only after checking existing objects and their writers; `kubectl create --dry-run=server` and `kubectl apply --dry-run=server` run the full validation without storing anything, which is the safe way to test both objects and rules. CEL rules (`x-kubernetes-validations`) cover what OpenAPI keywords cannot.

## Worth remembering

- `kubectl explain backuppolicy.spec --recursive`
- `kubectl apply --dry-run=server -f policy.yaml`
- `kubectl get crd <name> -o jsonpath='{.spec.versions[*].schema.openAPIV3Schema}'`

## What was broken

`report-operator` used three API operations its Role did not allow: listing pods, creating ConfigMaps and patching the status of a `Report`. The first 403 had been fixed by someone last week, so the operator got one step further and failed on the next one. Nobody had written down what the controller actually calls.

## The evidence

Every 403 in the log is a complete sentence: `User "system:serviceaccount:..." cannot list resource "pods" in API group "" in the namespace "k8smissions"`. `kubectl auth can-i <verb> <resource> --as=system:serviceaccount:<ns>:<sa>` reproduces any of them in a second. The operator handles each Report in sequence and moves on after the first failure, so the errors came one at a time.

## Why Kubernetes behaved this way

RBAC is purely additive and denies by default. A rule matches API group, resource and verb, and subresources are resources of their own: `reports` and `reports/status` are different entries, which is deliberate, because it lets an operator own the status of an object without being able to change its spec (and the reverse for users). Controllers built with client libraries cache and watch, which is why production operators usually need `list` and `watch` in addition to `get`.

## The fix

Add exactly the three rules, using the most specific verbs. The validator proves both sides: the work gets done, and `get secrets`, `delete nodes` and `*` are still refused.

## In production

Generate the rules from the controller's markers (kubebuilder's `+kubebuilder:rbac`), review them like code, and prefer a namespaced Role over a ClusterRole when the operator works in one namespace.

## Worth remembering

- `kubectl auth can-i --list --as=system:serviceaccount:<ns>:<sa> -n <ns>`
- `kubectl auth can-i patch <resource> --subresource=status --as=...`
- `kubectl get role,rolebinding -n <ns> -o yaml`

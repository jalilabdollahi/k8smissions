## What was broken

A mutating webhook that labels every new pod also matched the pod of its own server. After the server was scaled down and the webhook registered, the server could not be started again: the API server had to call the webhook to admit the pod, and the webhook's only backend was that pod. `failurePolicy: Fail` made the unreachable webhook a hard refusal, for `labeler-system` and for every application namespace the webhook covers.

## The evidence

`kubectl -n labeler-system describe rs` showed `FailedCreate ... failed calling webhook "labeler.platform.acme.io" ... no endpoints available for service "pod-labeler"`. The same message appeared for the `storefront` ReplicaSet in `shop`. `kubectl get endpoints pod-labeler -n labeler-system` was empty.

## Why Kubernetes behaved this way

Admission is synchronous and happens before the pod exists. The API server cannot know that a webhook is "its own" backend; it only evaluates `rules`, `namespaceSelector` and `objectSelector`. Failing closed is the safe default for a security webhook, and it creates this bootstrap loop unless the webhook excludes whatever it depends on.

The fix is an exclusion, expressed with `matchExpressions` on the automatic label `kubernetes.io/metadata.name`, added next to the `matchLabels` that keep the webhook away from system namespaces. Deleting the webhook gets the server back but turns off mutation for `shop`, which the validator also checks.

## In production

The same pattern protects `kube-system`: cert-manager, Gatekeeper and Kyverno all exclude their own namespace and control-plane namespaces by default. Use a short `timeoutSeconds`, run two replicas of the server, and think about `failurePolicy: Ignore` only for webhooks that are not a security boundary.

## Worth remembering

- `kubectl describe rs <name>` shows admission failures that `get pods` hides.
- `kubectl get mutatingwebhookconfiguration <name> -o jsonpath='{.webhooks[*].namespaceSelector}'`
- `kubectl run x --image=busybox --dry-run=server -o yaml` shows the object after mutation, without creating it.

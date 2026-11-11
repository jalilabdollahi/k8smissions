## What was broken

`feature-flags` ran as the `default` ServiceAccount, which has no permissions, so reading ConfigMap `flags` returned 403. The right account, `flags-reader`, with a narrow Role and a RoleBinding, already existed but no Deployment used it. Once it was selected, a second problem appeared: that ServiceAccount has `automountServiceAccountToken: false`, so the pod had no token at all.

## Evidence

The 403 message names the identity: `system:serviceaccount:k8smissions:default`. `get deploy -o yaml` shows no `serviceAccountName`. After the switch, the log said no token was found, and `kubectl exec ... ls /var/run/secrets/kubernetes.io/serviceaccount` fails.

## Why Kubernetes behaved this way

RBAC grants belong to subjects, and a pod's subject is chosen only by `spec.serviceAccountName`. The token volume is injected by the API server unless automounting is disabled, either on the ServiceAccount or on the pod; the pod setting takes precedence over the ServiceAccount's. A hardened ServiceAccount that switches automount off is correct for most workloads, so apps that really call the API opt back in.

## The fix

Set `serviceAccountName: flags-reader` and `automountServiceAccountToken: true` in the pod template. Adding the same value on the ServiceAccount also works but would affect every pod that uses it.

## In production

Give each workload its own ServiceAccount, turn automount off by default, and enable it only where the app speaks to the API. Never grant roles to `default`: it is shared by every pod that names no account.

## Commands worth remembering

- `kubectl auth can-i get configmap/flags --as=system:serviceaccount:<ns>:<sa>`
- `kubectl get pod <pod> -o jsonpath='{.spec.serviceAccountName}'`
- `kubectl create token <sa>` (a short-lived token for tests)

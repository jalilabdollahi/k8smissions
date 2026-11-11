**Fix**

1. `kubectl -n k8smissions logs deploy/feature-flags` shows the 403 for `system:serviceaccount:k8smissions:default`: the Deployment never names a ServiceAccount.
2. `kubectl -n k8smissions patch deploy feature-flags --type=merge -p '{"spec":{"template":{"spec":{"serviceAccountName":"flags-reader"}}}}'`
3. The new pod now fails with `no service account token found`: `flags-reader` has `automountServiceAccountToken: false`. Override it in the pod template:
   `kubectl -n k8smissions patch deploy feature-flags --type=merge -p '{"spec":{"template":{"spec":{"automountServiceAccountToken":true}}}}'`
4. `kubectl -n k8smissions rollout status deploy/feature-flags`

Do not bind the Role to `default`: every pod in the namespace would inherit the access.

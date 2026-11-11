**Binding `cluster-admin` (or a ClusterRole with wide rights) to make the 403s stop.** It works in one command and fails the least-privilege check: the validator asks whether the account can list Secrets in both namespaces, read nodes, delete pods or do anything at all.

**Fixing only the namespace the pods live in.** After the pod list works, the ConfigMap is still forbidden: a RoleBinding in `k8smissions` grants nothing in `platform-config`. The Role exists there; it needs its own binding, with the subject's namespace set to `k8smissions`.

**Not restarting the pods.** The account setting and the bindings are read when a pod is created (the token) or on every request (the bindings). Pods that came up while `automountServiceAccountToken` was still false have no token and stay NotReady until you run `kubectl rollout restart deploy/ledger-sync`.

**Editing the RoleBinding's `roleRef`.** It is immutable. Only the subjects change; if the role is wrong, delete and recreate the binding. Here the role is right and the subject name is the problem.

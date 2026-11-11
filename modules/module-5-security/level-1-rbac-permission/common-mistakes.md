## Mistakes on this level

- **Widening the rule to `resources: ["*"]`.** The crash stops, but the ServiceAccount can now read Secrets and exec into pods. The validator checks that `get secrets` and `create pods/exec` stay forbidden. Name `pods/log` only.
- **Binding the ServiceAccount to `view` or `cluster-admin`.** It works and breaks least privilege: other namespaces become readable. Fix the missing rule in the namespace Role.
- **Adding `list` or `watch` to `pods/log`.** The log endpoint needs `get`. Read the 403 message: it names the verb and the resource.
- **Waiting without restarting.** After several crashes the back-off between restarts grows to minutes. `kubectl rollout restart deploy/log-shipper` gives a fresh pod immediately.

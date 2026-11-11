1. `kubectl logs deploy/thumb-api` shows the server listening on `:5678`; the manifest only says `containerPort: 80`.
2. Service `thumb-api` has `targetPort: 80`, so it connects to a port nothing listens on.
3. `kubectl -n k8smissions patch service thumb-api --type=json -p '[{"op":"replace","path":"/spec/ports/0/targetPort","value":5678}]'` fixes it immediately, no pod restart needed.

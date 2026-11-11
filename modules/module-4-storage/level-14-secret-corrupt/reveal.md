# Reveal

`api-consumer` mounts the Secret key as a single file with `subPath: token`. The kubelet bind-mounts that one file into the container and never updates it, so the pod keeps the value from when it started. Restarting the pod would show the new value once and fail at the next rotation.

1. Compare: the Secret decodes to `tok-2025-11-7be204...`, `kubectl exec ... cat /etc/api/token` shows the older `tok-2025-11-a91f3c`.
2. Mount the whole volume as a directory (no `subPath`):

   ```bash
   kubectl patch deployment api-consumer -n k8smissions --type=json \
     -p '[{"op":"replace","path":"/spec/template/spec/containers/0/volumeMounts/1","value":{"name":"token","mountPath":"/etc/api","readOnly":true}}]'
   ```
3. `/etc/api/token` is now a link into a directory the kubelet swaps atomically on every rotation (it takes up to about a minute).

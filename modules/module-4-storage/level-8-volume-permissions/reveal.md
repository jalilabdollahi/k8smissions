# Reveal

The key file is created root-owned with mode `0400`. The app runs as uid 10001 and cannot read it, so it dies with `PermissionError`. Running as root would hide the problem but break the non-root requirement, and making the mode `0444` makes the app refuse the key as too open.

1. See the error: `kubectl logs deploy/writer-app -n k8smissions --previous` ends with `PermissionError: ... '/etc/signing/signing.key'`.
2. Give the volume's files a group that the app's user belongs to:

   ```bash
   kubectl patch deployment writer-app -n k8smissions --type=merge \
     -p '{"spec":{"template":{"spec":{"securityContext":{"fsGroup":10001}}}}}'
   ```

   With `fsGroup` set, the kubelet makes the files group-owned by 10001 and adds group read to the mode (0400 becomes 0440), which is exactly enough.
3. Wait for the rollout; `/status` reports `signed=ok uid=10001`.

Another correct fix: `defaultMode: 0440` together with `fsGroup`.

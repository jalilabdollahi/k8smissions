# Reveal

The claim `uploads` is mounted at `/var/uploads`, but the app is configured with `DATA_DIR=/srv/uploads`, so uploads go to the container's own writable layer and disappear with the pod.

1. Show the mismatch: `kubectl exec deploy/web-app -n k8smissions -- wget -qO- localhost:8080/status` reports `/srv/uploads`; `df` shows the volume only at `/var/uploads`.
2. Make them agree, for example by moving the mount to the app's directory:

   ```bash
   kubectl patch deployment web-app -n k8smissions --type=json \
     -p '[{"op":"replace","path":"/spec/template/spec/containers/0/volumeMounts/1/mountPath","value":"/srv/uploads"}]'
   ```

   (`kubectl set env deployment/web-app DATA_DIR=/var/uploads` works too.)
3. Wait for the rollout, then upload a file, delete the pod and download it again.

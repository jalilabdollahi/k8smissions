# Debrief: uploads that vanish

**What was broken.** The PersistentVolumeClaim `uploads` was bound and mounted, so every Kubernetes object looked healthy. But the application writes to `/srv/uploads` (set by `DATA_DIR`) and the volume sits at `/var/uploads`. Files went to the container's writable layer, which is thrown away with the pod.

**The evidence.** Nothing fails: there are no errors, no events, no restarts. The only signs are in the pod. `df -h` or `cat /proc/mounts` shows the volume mounted at `/var/uploads` and nowhere else, and the app's `/status` endpoint reports a different directory. Persistence bugs of this kind only show themselves when the pod is replaced.

**Why Kubernetes behaves this way.** A volume is just a directory mounted into the container at `mountPath`. Kubernetes does not know which paths your application writes to; it mounts what it was told to mount. Anything written outside a mount lives in the container filesystem and has the lifetime of the container, or the pod once it is rescheduled.

**The fix.** Make the application's data path and the volume's `mountPath` the same, by changing the mount or the application's setting. Both are valid; changing the config keeps the image-default layout, changing the mount keeps the app config.

**In production.** Test persistence explicitly after wiring a volume: write, delete the pod, read. Prefer a single config value for the data path, shared by the app config and the manifest (Helm values), so they cannot drift apart.

**Commands worth remembering**
- `kubectl exec <pod> -- df -h` and `cat /proc/mounts`: what is actually mounted.
- `kubectl get pod <pod> -o jsonpath='{.spec.containers[*].volumeMounts}'`
- `kubectl delete pod <pod>`: the cheapest persistence test.

# Debrief: the rotated token that never arrived

**What was broken.** `api-consumer` mounted Secret `api-token` with `subPath: token`, as one file at `/etc/api/token`. After last night's rotation the gateway accepted the new token while the consumer kept sending the one it started with, so every request was a 401. The Secret was right the whole time.

**The evidence.** The decoded Secret and `cat /etc/api/token` in the pod differ. The Deployment's `volumeMounts` entry shows `subPath: token`. `kubectl rollout restart` makes the symptom disappear, which is why it looks like a flaky app.

**Why Kubernetes behaves this way.** For a Secret or ConfigMap volume the kubelet writes a timestamped directory and swaps a `..data` symlink atomically; files in the volume are symlinks through it. A `subPath` mount bind-mounts the target of one file at container start, bypassing the symlink, so later swaps never reach it. This is documented, and is the same for ConfigMaps. Updates are not instant either: they arrive at the next kubelet sync, up to about a minute.

**The fix.** Remove `subPath` and mount the volume as a directory, here at `/etc/api`, so the application still reads `/etc/api/token`. No restart is needed at rotation time any more. The validator checks it by rotating the Secret itself and waiting for the pod to follow.

**In production.** If an app needs one file inside a directory that already has other content, mount the volume elsewhere and symlink, or use a reloader (Stakater Reloader) that rolls the pods on change. Make the application re-read the file instead of caching it at startup.

**Commands worth remembering**
- `kubectl exec <pod> -- ls -la <dir>`: `..data` and the symlinked file show a live volume.
- `kubectl get secret <name> -o jsonpath='{.data.<key>}' | base64 -d`
- `kubectl explain pod.spec.containers.volumeMounts.subPath`

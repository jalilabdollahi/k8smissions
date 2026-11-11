## Mistakes on this level

- **Setting `readOnlyRootFilesystem: false` (or deleting the securityContext).** The pods start, and the platform policy is broken. The validator checks the setting and tries to `touch` a file in `/`.
- **Mounting only the first path.** `/var/cache/nginx` fixes the first error, then nginx fails on `/var/run/nginx.pid`. After each change read `logs --previous` again instead of assuming it is done.
- **Mounting an `emptyDir` over `/etc/nginx` or `/usr/share/nginx/html`.** That hides the config or the page shipped in the image and nginx serves 404 or fails to start. Mount only the directories that need writes.
- **Editing the pod, not the Deployment.** The pod spec cannot gain volumes, and a recreated pod loses the change. Patch the Deployment.

# Debrief: permission denied on the signing key

**What was broken.** The pod ran as uid 10001 (non-root), while the Secret volume `signing-keys` was mounted with `defaultMode: 0400`. Secret files are owned by root, so a mode of `0400` means only root can read them. The app tried to read its key on start and failed with `Permission denied`, and the Deployment crash-looped.

**The evidence.** The log (`kubectl logs --previous`) ended in `PermissionError` naming the key file. The pod's `securityContext` showed `runAsUser: 10001`, and the volume definition showed `defaultMode: 0400`. Together those answer the question: who owns the file, who reads it, and what the mode allows.

**Why Kubernetes behaves this way.** Volumes follow ordinary Unix permissions. Secret and ConfigMap files are root-owned; Kubernetes does not know which user your image uses. `fsGroup` is the pod-level tool for this: the kubelet changes the group of the volume's files to that GID and makes them group-readable (so `0400` becomes `0440`) and adds the GID to the container's supplementary groups. Loosening the mode to `0444` also lets uid 10001 read the file, but this app, like `ssh`, rejects a key that is readable by everyone, and in general a world-readable secret is a leak.

**The fix.** Set `fsGroup: 10001` on the pod, or an equivalent `0440` mode plus a group. Running as root passes the crash test and fails the requirement.

**In production.** Combine `runAsNonRoot`, `fsGroup` and the narrowest `defaultMode` that works. Remember `fsGroup` also recursively changes ownership of persistent volumes at mount time, which can be slow on large volumes (`fsGroupChangePolicy: OnRootMismatch` helps).

**Commands worth remembering**
- `kubectl exec <pod> -- ls -ln /path` and `id`
- `kubectl explain pod.spec.securityContext.fsGroup`
- `kubectl get pod <pod> -o jsonpath='{.spec.securityContext}'`

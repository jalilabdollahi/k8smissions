## What was broken

`status-page` ran nginx with `readOnlyRootFilesystem: true`. nginx writes to its own image at startup: temporary directories under `/var/cache/nginx` and the pid file in `/var/run`. Every write failed with `Read-only file system`, nginx exited and the pods went into CrashLoopBackOff.

## Evidence

`kubectl logs --previous` printed `mkdir() "/var/cache/nginx/client_temp" failed (30: Read-only file system)`. Fixing only that path moves the failure to `open() "/var/run/nginx.pid" failed`: nginx hits its writes in order, so each one shows up only after the previous is solved.

## The fix

The root filesystem stays read-only (that is the policy). Writable scratch space is added explicitly as `emptyDir` volumes mounted at exactly the paths the process needs. The security property is kept: an attacker who gets code execution still cannot modify binaries or config in the image layers; only the mounted scratch directories accept writes.

## In production

Find the write paths before enforcing the policy: run the image once with a writable filesystem and look at `kubectl exec ... -- find / -xdev -newer ... -type f`, or at the image documentation. `nginxinc/nginx-unprivileged` plus tmpfs-backed `emptyDir` (`medium: Memory`) is a common pairing. Combine with `runAsNonRoot` and dropped capabilities so the read-only setting is one layer among several.

## Commands worth remembering

- `kubectl logs <pod> --previous`
- `kubectl explain pod.spec.volumes.emptyDir`
- `kubectl exec <pod> -- touch /x` to test whether a path is writable

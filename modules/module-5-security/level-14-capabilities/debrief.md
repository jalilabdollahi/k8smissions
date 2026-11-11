## What was broken

`edge-nginx` runs its master process as root and had `capabilities: drop: ["ALL"]` applied by a hardening sweep. Root without capabilities is an ordinary user in disguise: nginx could no longer change ownership of its temp directories, switch to its worker user, or bind port 80, so it died on one operation after another.

## Evidence

Each start-up failure names a syscall: `chown(...) failed`, `setgid(101) failed`, `bind() to 0.0.0.0:80 failed (13: Permission denied)`. Only the first one shows at a time, because nginx stops at the first error. `kubectl exec ... grep Cap /proc/1/status` prints the capability masks (`CapEff` is the set in force) once the pod runs.

## Why Kubernetes behaved this way

The container runtime starts a container with a default set of about a dozen capabilities. `drop: ["ALL"]` empties it and `add` lists exceptions. Capabilities split root's powers: `CHOWN` changes ownership, `SETUID`/`SETGID` change identity, `NET_BIND_SERVICE` allows ports below 1024. The set a process needs is found by reading errors or by tracing, not by guessing.

## The fix

Keep `drop: ["ALL"]` and add back `CHOWN`, `SETUID`, `SETGID` and `NET_BIND_SERVICE`. That is a four-bit `CapEff`, without `NET_RAW`, `SYS_ADMIN` or `DAC_OVERRIDE`. Nothing needs `privileged`.

## In production

The better answer is often not to need capabilities: `nginxinc/nginx-unprivileged` on port 8080 with `runAsNonRoot` needs none. When a root image must stay, list the capabilities explicitly in the manifest so reviewers see them. Pod Security `baseline` allows only a short list in `add`, and `restricted` allows just `NET_BIND_SERVICE`.

## Commands worth remembering

- `kubectl exec <pod> -- grep Cap /proc/1/status`
- `capsh --decode=<hex mask>` on a machine that has libcap
- `kubectl logs <pod> --previous`

## What went wrong

`runAsNonRoot: true` tells Kubernetes to enforce that the container does not start as root — but it does not tell Kubernetes *what* user to run as. The nginx image defaults to UID 0. Kubernetes detects this conflict and refuses to start the container.

## Fix

Add `runAsUser` with a non-zero UID and harden the container further:

```yaml
spec:
  containers:
  - name: nginx
    image: nginxinc/nginx-unprivileged:latest
    ports:
    - containerPort: 8080
    securityContext:
      runAsNonRoot: true
      runAsUser: 1000
      allowPrivilegeEscalation: false
      capabilities:
        drop:
        - ALL
```

Note: switch to `nginx-unprivileged` and port 8080, since non-root processes cannot bind to ports below 1024.

## Why this matters

Running containers as root means a process escape gives an attacker root on the host. `runAsNonRoot` paired with an explicit `runAsUser` is a two-step defense: Kubernetes rejects root at admission, and the UID pins the runtime identity. `allowPrivilegeEscalation: false` closes the setuid door even if someone does get code execution.
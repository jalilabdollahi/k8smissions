## What went wrong

Without a `securityContext`, the container runs as whatever user the image specifies. `busybox:1.36` defaults to UID 0 (root). The namespace's Pod Security admission controller checks this at creation time and rejects the pod.

## Fix

Add a securityContext at the pod level and harden the container:

```yaml
spec:
  securityContext:
    runAsNonRoot: true
    runAsUser: 1000
  containers:
  - name: app
    image: busybox:1.36
    command:
    - /bin/sh
    - -c
    - id; sleep 3600
    securityContext:
      allowPrivilegeEscalation: false
      readOnlyRootFilesystem: true
```

## Why this matters

The pod-level `securityContext` sets defaults for all containers. The container-level `securityContext` overrides or supplements those defaults. `readOnlyRootFilesystem: true` adds defense-in-depth: even if an attacker achieves code execution, they cannot write malicious files to the container's filesystem. You can verify the running user with `kubectl exec insecure-pod -- id` after the fix — it should show `uid=1000`.
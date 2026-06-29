## What went wrong

The namespace has the label `pod-security.kubernetes.io/enforce: restricted`. The restricted standard requires: non-root user, no privilege escalation, all capabilities dropped, and a seccomp profile. The pod violates all four.

## Fix

```yaml
spec:
  securityContext:
    runAsNonRoot: true
    runAsUser: 1000
    seccompProfile:
      type: RuntimeDefault
  containers:
  - name: app
    image: nginx:latest
    securityContext:
      runAsNonRoot: true
      runAsUser: 1000
      allowPrivilegeEscalation: false
      capabilities:
        drop:
        - ALL
```

## Why this matters

Pod Security Standards (PSS) are built into Kubernetes since 1.25 and replace the deprecated PodSecurityPolicy. Three tiers exist: `privileged` (no restrictions), `baseline` (blocks known privilege escalations), and `restricted` (requires all the hardening above). The `enforce` label rejects non-compliant pods at admission; `warn` lets them through but shows a warning; `audit` logs them. The restricted profile aligns with CIS Kubernetes Benchmark recommendations for production workloads.
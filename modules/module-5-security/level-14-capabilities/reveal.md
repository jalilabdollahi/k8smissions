## What went wrong

Linux capabilities are fine-grained permissions that grant specific kernel-level privileges. `NET_BIND_SERVICE` is the one that allows binding to privileged ports (ports < 1024). When you drop ALL capabilities, you drop this one too. A non-root process without it gets `EACCES` (permission denied) when calling `bind(80)`.

## Fix

Drop everything and add back only what's needed:

```yaml
securityContext:
  runAsNonRoot: true
  runAsUser: 1000
  capabilities:
    drop:
    - ALL
    add:
    - NET_BIND_SERVICE
```

## Why this matters

This is the principle of least privilege applied to Linux capabilities. Rather than running as root (which implicitly has all capabilities), you: (1) drop all capabilities first, then (2) add back only the specific ones the process requires. This limits blast radius if the process is ever compromised — the attacker gets `NET_BIND_SERVICE` but not `SYS_ADMIN`, `CAP_NET_RAW`, `SYS_PTRACE`, and all the other dangerous capabilities. You can list available capabilities with `man 7 capabilities`.
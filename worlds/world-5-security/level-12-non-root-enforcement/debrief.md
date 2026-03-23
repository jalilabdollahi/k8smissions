# Root Rejected

## What Was Broken
The pod had no securityContext and the image default was UID 0 (root). A namespace-level PodSecurity policy (or admission webhook) rejected the pod because it ran as root.

## The Fix
Set `securityContext.runAsNonRoot: true` and `runAsUser: <non-zero>` on the pod spec. Also add `allowPrivilegeEscalation: false` at the container level for defense in depth.

## Why It Matters
Running as root inside a container is a OWASP-flagged vulnerability. If the container is compromised, root access inside maps to a powerful UID on the host kernel. Always use non-root UIDs in production. Kubernetes 1.25+ enforces Pod Security Standards natively.

## Pro Tip
Pod Security Standards have three levels: Privileged (no restrictions), Baseline (prevent obviously dangerous settings), Restricted (hardened). Label namespaces: `kubectl label namespace <ns> pod-security.kubernetes.io/enforce=restricted`

## Concepts
securityContext, runAsNonRoot, runAsUser, Pod Security Standards, least privilege

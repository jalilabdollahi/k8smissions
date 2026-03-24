# Common Mistakes — Root Rejected

## Mistake 1: Using runAsUser: 0 explicitly

**Wrong approach:** Setting runAsUser: 0 — this is explicitly root and will always be rejected by strict policies

**Correct approach:** Choose any non-zero UID; 1000 is a common convention for application users

## Mistake 2: Setting runAsNonRoot: true without runAsUser

**Wrong approach:** If the image has USER 0 by default, runAsNonRoot: true alone will fail at runtime

**Correct approach:** Set both runAsNonRoot: true AND runAsUser: <non-zero>

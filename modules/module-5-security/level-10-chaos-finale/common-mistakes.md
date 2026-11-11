## Mistakes on this level

- **Relaxing the namespace label to `baseline` or `privileged`.** Pods appear immediately, but the Pod Security guard rail is gone, and the validator requires `enforce=restricted` plus a rejected privileged dry-run.
- **Deleting `settle-quota` or raising its limits.** The right fix is to give the pods limits that fit; the quota is the team's cost control.
- **Granting the ServiceAccount a wildcard or Secret access to silence the 403.** One missing verb (`get`) was enough; `get secrets`, `create pods` and cluster-wide access are all tested as forbidden.
- **Deleting the NetworkPolicy, or allowing the whole namespace.** `settlement` then reaches the database, but so does `rogue`; the validator tests that `rogue` is still blocked.
- **Fixing in the wrong place.** Looking for pods when there are none: start at the ReplicaSet events, and re-read them after every fix.

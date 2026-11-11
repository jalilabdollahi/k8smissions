## Common mistakes

- **Deleting the failing pods.** The ReplicaSet recreates them from the same template and the new pods hit the same bad tag.
- **Switching to `latest`.** It would pull, but unpinned tags make the next incident impossible to reproduce. Use the same pinned tag as the canary.
- **Editing `storefront-canary` by mistake.** It is the healthy reference. The validator checks it did not change.
- **Looking at the container logs.** A container that never started has no logs; the evidence is in the pod's Events.

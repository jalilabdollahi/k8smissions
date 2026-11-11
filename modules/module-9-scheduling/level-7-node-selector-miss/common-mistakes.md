## Searching only the Deployment

The manifest is internally consistent: the pod is asking for something reasonable. The mismatch is between the manifest and a node label, so look at both sides.

## Relabelling the HDD node as `ssd`

Both nodes then match, pods spread across them, and half of the model weights end up on a slow disk. The check requires the disk labels to describe the real hardware.

## Deleting the whole affinity block

Pods schedule anywhere, including the HDD worker, and the disk requirement is lost. If you edit the pod side, keep the disk requirement and drop only what is not true any more.

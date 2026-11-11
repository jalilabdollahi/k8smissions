## Common mistakes

- **Labelling the HDD node `disktype=ssd`.** The pod starts, but on the slow disk. The point of the selector is to protect the cache from that, and the check looks at the node that actually has the SSD.
- **Trying to `kubectl edit pod` and change the selector.** The API server rejects updates to a pod's `nodeSelector`. Delete and recreate the pod, or fix the labels instead.
- **Looking for logs.** A Pending pod has none; the answer is in the scheduler's event on `describe pod`.
- **Removing the `nodeSelector` entirely.** The pod would be scheduled anywhere, including the HDD worker, and the objective forbids that.

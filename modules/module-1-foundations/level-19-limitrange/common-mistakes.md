## Common mistakes

- **Describing the Deployment or pods.** The Deployment looks fine and there are no pods. The refusal is recorded on the ReplicaSet's events.
- **Lowering the limit to 128Mi to fit the ratio.** Pods are admitted, then each render is OOMKilled. The check sends real render requests.
- **Deleting or editing the LimitRange.** It is a shared team rule; the check requires it to still enforce a ratio of 2 or less.
- **Raising only the request above the limit.** Requests cannot exceed limits, so the pod is rejected for a different reason; choose a request of at least half the limit.

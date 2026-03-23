# Common Mistakes — The Unmovable Update

## Mistake 1: Thinking the image is invalid

**Wrong approach:** Assuming nginx:1.25 doesn't exist and changing the image tag

**Correct approach:** The image is fine; the rollout strategy itself blocks progress

## Mistake 2: Setting maxUnavailable: 3 (equal to replicas)

**Wrong approach:** This works but causes downtime — all 3 pods are killed before new ones start

**Correct approach:** Prefer maxSurge:1 maxUnavailable:0 for zero-downtime rolling updates

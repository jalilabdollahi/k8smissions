# Common Mistakes — Frozen Canary

## Mistake 1: Deleting the rollout to unblock

**Wrong approach:** Deleting the Rollout — this deletes the workload and causes outage

**Correct approach:** Use kubectl argo rollouts promote or fix the pause step duration

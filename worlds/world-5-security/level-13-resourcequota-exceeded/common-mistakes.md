# Common Mistakes — Quota Breached

## Mistake 1: Deleting the quota to fix the problem

**Wrong approach:** Removing the ResourceQuota — this removes all guardrails from the namespace

**Correct approach:** Fix the pod resources to be within the quota; quotas exist to protect the cluster

## Mistake 2: Increasing quota instead of fixing the pod

**Wrong approach:** Upping quota because it is easiest — the pod is probably over-requested

**Correct approach:** Right-size the pod's requests based on actual profiled usage

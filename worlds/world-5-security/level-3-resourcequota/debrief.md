# Quota Exceeded

## Situation
Namespace has ResourceQuota: max 2 CPU / 4Gi memory. Three pods each request 1 CPU. Third pod can't schedule.

## Successful Fix
Reduce CPU request per pod to 600m OR delete unused pods OR request quota increase (update ResourceQuota)

## What To Validate
Use the validator to confirm the repaired state.

## Why It Matters
Review how the fix changed the cluster behavior for Quota Exceeded.

## Concepts
ResourceQuota, LimitRange, requests.cpu, requests.memory, namespace-level governance

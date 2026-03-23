# Common Mistakes — Deleted Data

## Mistake 1: Using Recycle policy

**Wrong approach:** Setting reclaimPolicy: Recycle — this policy is deprecated and removed in newer k8s versions

**Correct approach:** Use Retain; add manual cleanup or an operator for automated recycling

## Mistake 2: Expecting Retained PV to auto-bind to new PVC

**Wrong approach:** A PV in Released state still has the old claimRef — new PVCs won't bind to it

**Correct approach:** Remove claimRef manually: kubectl patch pv <name> -p '{"spec":{"claimRef":null}}'

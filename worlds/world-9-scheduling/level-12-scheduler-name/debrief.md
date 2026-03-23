# Wrong Scheduler

## What Was Broken
The ML training pod used the default scheduler. The ML-aware scheduler reserves GPU-optimized nodes and handles topology for distributed training — the pod needed to be assigned to it explicitly.

## The Fix
Add 'schedulerName: ml-scheduler' to the pod spec.

## Why It Matters
Multiple schedulers can coexist in a cluster. The default scheduler handles all pods with no schedulerName or those explicitly specifying 'default-scheduler'. Custom schedulers register themselves and process pods bearing their name.

## Pro Tip
Check what schedulers are running: kubectl get pods -n kube-system | grep scheduler. Custom schedulers often have a human-readable name in their config that must match the schedulerName field exactly.

## Concepts
schedulerName, custom scheduler, default-scheduler, pod spec, GPU scheduling

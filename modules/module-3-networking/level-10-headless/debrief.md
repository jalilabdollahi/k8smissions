# StatefulSet Can't Reach Itself

## Situation
StatefulSet pods can't find each other via DNS (pod-0.svc-name). Service has a ClusterIP instead of being headless.

## Successful Fix
Set clusterIP: None to make service headless

## What To Validate
Use the validator to confirm the repaired state.

## Why It Matters
Review how the fix changed the cluster behavior for StatefulSet Can't Reach Itself.

## Concepts
Headless service, clusterIP: None, StatefulSet DNS format, <pod>.<svc>.<ns>.svc.cluster.local

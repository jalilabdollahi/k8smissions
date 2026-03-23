# The Headless Mystery

## What Was Broken
The StatefulSet's `serviceName: db-svc` pointed to a regular ClusterIP Service. StatefulSets require a headless Service (`clusterIP: None`) to generate per-pod stable DNS records. Without it, pod identity and network address are undefined.

## The Fix
Create (or patch) the governing Service to have `clusterIP: None` and update `spec.serviceName` in the StatefulSet to reference it.

## Why It Matters
StatefulSet provides three guarantees: stable storage (PVC per pod), stable network identity (predictable hostname), and ordered deployment/scaling. The headless Service is the mechanism behind stable network identity. Each pod gets a DNS A record: `<pod-name>.<service-name>.<ns>.svc.cluster.local`.

## Pro Tip
You cannot change `spec.serviceName` in-place on an existing StatefulSet — it is immutable. You must delete and recreate the StatefulSet (with `--cascade=orphan` to keep pods) or use a rolling recreation strategy.

## Concepts
StatefulSet, headless service, clusterIP: None, stable hostname, DNS

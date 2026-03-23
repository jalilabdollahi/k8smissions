# Nodes Won't Scale Up

## Situation
HPA scaled pods to 20 but nodes can't fit them all. Cluster Autoscaler is installed but not scaling up new nodes. Root cause: Cluster Autoscaler has wrong node group annotation.

## Successful Fix
Patch Cluster Autoscaler deployment with correct node group (or on kind: demonstrate concept with node taints simulation)

## What To Validate
All pods eventually scheduled (or CA behavior explained)

## Why It Matters
Review how the fix changed the cluster behavior for Nodes Won't Scale Up.

## Concepts
Cluster Autoscaler, node groups, scale-up triggers, cloud provider integration, kind simulation limitations

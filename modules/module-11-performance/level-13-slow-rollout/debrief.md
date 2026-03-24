# Deployment Takes Hours

## What Was Broken
maxSurge: 0, maxUnavailable: 1 allows only one pod to be replaced at a time. For a 100-replica Deployment, this is 100 sequential pod replacements. Each pod needs 2+ minutes to start → 3+ hours for a full rollout.

## The Fix
Set maxSurge: 10 and maxUnavailable: 0 for fast, zero-downtime rolouts. 10 pods update in parallel without reducing available capacity.

## Why It Matters
maxSurge vs maxUnavailable tradeoffs: maxSurge > 0 = create extra pods before removing old (needs extra capacity, zero-downtime). maxUnavailable > 0 = remove old pods before creating new (no extra capacity, brief reduced availability). For prod, prefer maxSurge.

## Pro Tip
Use percentage strings for scale-independent configuration: maxSurge: 25% and maxUnavailable: 0% works correctly regardless of replica count changes.

## Concepts
maxSurge, maxUnavailable, rolling update, deployment speed, parallel rollout

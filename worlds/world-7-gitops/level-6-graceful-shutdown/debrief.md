# Requests Dropped During Rollout

## Situation
During rolling update, in-flight HTTP requests fail with connection reset. Pod termination kills process without drain.

## Successful Fix
Add lifecycle.preStop: exec sleep 15 Set terminationGracePeriodSeconds: 60

## What To Validate
Rolling update completes with zero dropped connections

## Why It Matters
Review how the fix changed the cluster behavior for Requests Dropped During Rollout.

## Concepts
Pod termination lifecycle (SIGTERM → grace period → SIGKILL), preStop hooks, connection draining, zero-downtime deploys

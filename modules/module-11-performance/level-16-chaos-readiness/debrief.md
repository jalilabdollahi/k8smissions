# Chaos Unready

## What Was Broken
Only 2 replicas. A 50% pod kill chaos experiment left 1 pod running. With the full traffic load on 1 pod, it became overloaded and the service effectively went down.

## The Fix
Increase to 5+ replicas with topology spread. Scale so that losing 50% of pods still leaves enough capacity for reduced but functioning service.

## Why It Matters
Chaos engineering best practices: define steady state (what is 'normal'), hypothesis (app should serve 95% of requests with 50% pod loss), run experiment, verify hypothesis. If hypothesis fails, fix resilience, try again.

## Pro Tip
Under-provisioning is the #1 cause of chaos experiment failures. Run chaos experiments in staging first, understand blast radius, fix weak points before production chaos testing.

## Concepts
chaos engineering, replicas, topology spread, resilience, fault tolerance

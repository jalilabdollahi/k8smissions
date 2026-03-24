# OOM Killed Daily

## What Was Broken
VPA was configured with updateMode: Off. It collected recommendations but never applied them. The pod continued running with its original too-low memory limit, getting OOMKilled regularly.

## The Fix
Change updateMode to Auto. VPA will analyze historical usage and set appropriate memory limits automatically.

## Why It Matters
VPA modes: Off (recommend only), Initial (set on pod create only), Recreate (update by pod restart), Auto (current equivalent to Recreate). Use Initial for jobs (no restart), Auto for long-running services.

## Pro Tip
VPA and HPA can conflict if both scale replicas. Use HPA for horizontal scaling (replicas) and VPA for vertical scaling (requests/limits). Don't use both on the same Deployment unless VPA is in Initial mode.

## Concepts
VPA, updateMode, OOMKilled, resource recommendations, autoscaling

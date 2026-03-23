# Frozen Rollout

## What Was Broken
The Deployment had `spec.paused: true`. This is a legitimate feature used when you want to batch multiple config changes before triggering a single rollout. If forgotten, rollouts silently freeze.

## The Fix
Use `kubectl rollout resume deployment/<name> -n <ns>` — the dedicated command for this. Alternatively patch `spec.paused: false`.

## Why It Matters
The pause/resume workflow is safe and intentional. The danger is when someone pauses during debugging and forgets. Always check `kubectl rollout status` — the 'paused' message is clearly visible.

## Pro Tip
You can chain changes while paused then resume once: pause → change image → change env → change resources → resume. This prevents three separate rollouts from happening.

## Concepts
Deployment, rollout pause, rollout resume, kubectl rollout, rolling update

# Reverted Release

## What Was Broken
The Rollout used nginx:bad-tag (a non-existent image), causing the analysis run to fail. Argo Rollouts aborted and set status to Degraded. The rollback restored the previous stable revision.

## The Fix
Fix the root cause (bad image), update the rollout spec, then retry the rollout.

## Why It Matters
Degraded state means the rollout is stuck — it can't proceed forward (bad new version) and won't auto-retry. Human intervention required. This is the safety net working as intended.

## Pro Tip
Check rollout history: kubectl argo rollouts history rollout web-rollout -n k8smissions. Shows all revisions and which is stable/canary.

## Concepts
Argo Rollouts, Degraded, abort, retry, rollback

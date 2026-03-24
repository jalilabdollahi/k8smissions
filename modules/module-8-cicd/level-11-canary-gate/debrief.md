# Frozen Canary

## What Was Broken
The Argo Rollout canary step had `pause: {}` with no duration — an intentional manual gate. No one approved the promotion, so it waited indefinitely.

## The Fix
Either promote manually with 'kubectl argo rollouts promote' or change the step to a timed pause.

## Why It Matters
Manual gates are valuable for high-risk releases. Automated gates (based on metrics analysis) are better for routine releases. Know when to use each based on deployment risk level.

## Pro Tip
Argo Rollouts has a dashboard: kubectl argo rollouts dashboard. It shows rollout status, step progress, and the promote button graphically.

## Concepts
Argo Rollouts, canary, manual gate, promotion, step pause

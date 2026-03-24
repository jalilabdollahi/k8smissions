# The Drift

## What Was Broken
ArgoCD Application had `selfHeal: true`. This is the GitOps golden path — live cluster state that diverges from git is automatically corrected. Manual `kubectl scale` directly is treated as a drift and reverted.

## The Fix
Disable `selfHeal: false` for Applications that legitimately need manual overrides. Or better: commit the desired replica count to git and let ArgoCD sync it.

## Why It Matters
GitOps drift detection is a feature, not a bug. It ensures the cluster always reflects what's in git. If you need temporary scale changes (e.g., incident response), disable self-heal during the incident then re-enable. Consider an emergency `kubectl annotate` escape hatch in your ArgoCD config.

## Pro Tip
ArgoCD `prune: true` deletes resources not in git. `selfHeal: true` restores resources that differ from git. These are separate — you can have prune without selfHeal. Understand both before enabling.

## Concepts
ArgoCD, selfHeal, GitOps, drift detection, syncPolicy, automated sync

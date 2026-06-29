## What went wrong

`selfHeal: true` is a deliberate GitOps enforcement feature — it ensures the cluster always matches Git, even if someone runs `kubectl` directly. This is usually desirable. But when you need a temporary manual override (emergency scale-up during an incident), self-healing fights you.

## Fix

```yaml
syncPolicy:
  automated:
    selfHeal: false
    prune: true
```

## Why this matters

This level illustrates the core GitOps tension: Git is the source of truth, but emergencies sometimes require immediate manual action. Three approaches:
1. **Disable self-heal** (this fix) — allows manual overrides but permits drift
2. **Update Git first** — make the change in Git, ArgoCD applies it; purist GitOps, but slower
3. **Suspend the Application** — `argocd app set my-app --sync-policy none` temporarily

For production incidents, option 3 is often best: suspend ArgoCD, apply the emergency fix manually, then commit the change to Git and re-enable sync. This preserves the GitOps audit trail while unblocking the incident.
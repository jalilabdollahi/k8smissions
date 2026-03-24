# Common Mistakes - Level 7: Secrets in Git? Never.

## Fastest First Checks
```bash
helm status <release> -n k8smissions || true
argocd app get <app> || true
kubectl get all -n k8smissions
```

## ❌ Mistake #1: Patching the live cluster instead of the source of truth

**What players try:**
Players use `kubectl edit` to hot-fix Secrets in Git? Never. and move on.

**Why it fails:**
GitOps and release tools will overwrite that drift on the next sync, reconcile, or Helm upgrade.

**Correct approach:**
Make the change in the declarative source that owns the resource. In this level the key focus is GitOps source of truth and reconciliation.

**Key learning:**
In GitOps, the winning fix is the one that survives reconciliation.
## ❌ Mistake #2: Looking at pods but not the delivery controller

**What players try:**
Players check workload pods without checking Helm history, ArgoCD sync status, or Kustomize overlay intent.

**Why it fails:**
Delivery failures are often explained by the release layer before the pod layer.

**Correct approach:**
Inspect the release or sync controller first, then confirm what it rendered into the cluster.

**Key learning:**
The deployment tool is part of the system you are debugging.
## ❌ Mistake #3: Forgetting dependencies around the application

**What players try:**
Players fix the app manifest but miss prerequisites like namespaces, secrets, hooks, or supporting resources.

**Why it fails:**
A perfectly valid app spec can still remain OutOfSync, unhealthy, or blocked if the surrounding dependency chain is incomplete.

**Correct approach:**
Check the environment contract around the app before assuming the chart or manifest is the only issue.

**Key learning:**
Production delivery includes prerequisites, not just the main workload YAML.
## ❌ Mistake #4: No verification path back to stable state

**What players try:**
Players apply multiple delivery changes at once and have no idea which one fixed it.

**Why it fails:**
That makes rollback harder and weakens the lesson from the incident.

**Correct approach:**
Use revision history, sync status, or a single reversible change, then validate. End goal: Secret exists in cluster but source is ESO, not Git

**Key learning:**
Controlled delivery work is incremental, observable, and reversible.

## What To Prove Before You Move On
- The declared source of truth and the live cluster match again.
- You checked the controller status instead of only the workload pods.
- Secret exists in cluster but source is ESO, not Git

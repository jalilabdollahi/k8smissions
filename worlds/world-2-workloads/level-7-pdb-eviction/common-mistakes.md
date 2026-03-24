# Common Mistakes - Level 7: Maintenance is Stuck

## Fastest First Checks
```bash
kubectl get deploy,statefulset,rs -n k8smissions
kubectl rollout status deployment/<name> -n k8smissions
kubectl describe deployment <name> -n k8smissions
```

## ❌ Mistake #1: Editing pods instead of the controller

**What players try:**
Players patch an individual pod in Maintenance is Stuck because it is the easiest object to see.

**Why it fails:**
Deployments, StatefulSets, Jobs, and HPAs recreate pods from their own templates. A pod-only fix is wiped out on the next reconciliation loop.

**Correct approach:**
Find the owning controller and change the template or strategy there, then watch the rollout.

**Key learning:**
Controllers own pods. Sustainable fixes live at the controller layer.
## ❌ Mistake #2: Skipping rollout history and status

**What players try:**
Players apply a change and jump straight to validation.

**Why it fails:**
A rollout can still be progressing, stuck, or paused even if a few pods look healthy for a moment.

**Correct approach:**
Use rollout status, describe the controller, and inspect related ReplicaSets before deciding the fix worked.

**Key learning:**
Healthy pods are useful evidence, but controller status is the source of truth for workload health.
## ❌ Mistake #3: Confusing readiness, availability, and desired state

**What players try:**
Players count pods manually and stop there.

**Why it fails:**
A rollout can have the right replica count while still serving zero traffic because probes, surge rules, or disruption budgets are blocking availability.

**Correct approach:**
Verify the workload from the controller perspective and the traffic perspective. In this level the focus is rollout and controller state.

**Key learning:**
Replica count alone does not prove safe delivery.
## ❌ Mistake #4: Making a traffic change without a rollback plan

**What players try:**
Players switch selectors, versions, or rollout strategy in one jump and hope it holds.

**Why it fails:**
Blue-green, canary, and rollout strategy changes are safe only when you know how to undo them quickly.

**Correct approach:**
Use the smallest reversible change, verify behavior, then continue. Success target: kubectl drain succeeds without error

**Key learning:**
Good rollout work is as much about controlled rollback as forward progress.

## What To Prove Before You Move On
- The controller reports the desired number of ready replicas.
- You verified rollout status instead of trusting a single pod snapshot.
- kubectl drain succeeds without error

# Common Mistakes - Level 4: Too Greedy

## Fastest First Checks
```bash
kubectl describe pod <pod> -n k8smissions
kubectl get nodes --show-labels
kubectl describe node <node>
```

## ❌ Mistake #1: Guessing instead of reading Pending events

**What players try:**
Players see an unscheduled pod in Too Greedy and immediately start changing manifests.

**Why it fails:**
The scheduler usually tells you exactly what constraint failed: labels, taints, insufficient CPU/memory, affinity, or policy.

**Correct approach:**
Describe the pod first and let the scheduler message narrow the fix.

**Key learning:**
Pending is an explanation-rich state. Read it before guessing.
## ❌ Mistake #2: Treating constraints like preferences

**What players try:**
Players assume node selectors, required affinity, taints, or hard resource requests are flexible hints.

**Why it fails:**
Required scheduling constraints are binary. A single mismatch prevents placement completely.

**Correct approach:**
Compare the pod requirements directly against cluster reality with a focus on requests, capacity, and scheduler fit.

**Key learning:**
Scheduling is constraint matching, not best-effort magic.
## ❌ Mistake #3: Confusing requests, limits, and actual usage

**What players try:**
Players check current node usage but ignore what the scheduler reserves for the pod.

**Why it fails:**
Scheduling decisions are based on requests and allocatable capacity, not on what a workload happens to use right now.

**Correct approach:**
Verify requests, allocatable capacity, and taints/labels together before changing anything.

**Key learning:**
Placement depends on reserved capacity and policy, not just live metrics.
## ❌ Mistake #4: Stopping before the pod is truly placeable

**What players try:**
Players update one constraint and assume the scheduling problem is gone.

**Why it fails:**
There can be a second blocker behind the first one, especially in capacity or multi-constraint scenarios.

**Correct approach:**
Re-describe the pod after every change and keep going until the scheduler has no remaining objections. Final target: Pod scheduled and Running

**Key learning:**
Scheduling fixes are complete only when every constraint chain is satisfied.

## What To Prove Before You Move On
- The pod can now land on a node that satisfies its constraints.
- You verified labels, taints, requests, or capacity instead of guessing.
- Pod scheduled and Running

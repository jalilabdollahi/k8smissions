# Common Mistakes - Level 11: Sidecar Sabotage

## Fastest First Checks
```bash
kubectl get pods -n k8smissions
kubectl describe pod <pod> -n k8smissions
kubectl logs <pod> -n k8smissions --previous
```

## How to See All Containers in a Pod

A multi-container pod has several containers running side by side. To list them:

```bash
# Shows all container names under .spec.containers[*].name
kubectl get pod app-with-logging -n k8smissions -o jsonpath='{.spec.containers[*].name}'

# Or read them from describe output (look for "Containers:" section)
kubectl describe pod app-with-logging -n k8smissions
```

Once you know the container names, target a specific one with `-c`:

```bash
# View logs of a specific container
kubectl logs app-with-logging -n k8smissions -c log-sidecar

# View previous (crashed) logs of a specific container
kubectl logs app-with-logging -n k8smissions -c log-sidecar --previous

# Open a shell into a specific container
kubectl exec -it app-with-logging -n k8smissions -c log-sidecar -- sh
```

Without `-c`, kubectl defaults to the first container and may silently miss the broken one.

## ❌ Mistake #1: Treating the status as the root cause

**What players try:**
Players see a failing pod in Sidecar Sabotage and immediately edit random fields without first checking why the container stopped.

**Why it fails:**
Statuses like CrashLoopBackOff, ImagePullBackOff, and OOMKilled are symptoms. The real answer is usually in events, exit reasons, or the last container logs.

**Correct approach:**
Start from image pull and registry resolution: inspect the pod, read the events, and only then change the manifest field that actually caused the failure.

**Key learning:**
Kubernetes tells you what happened before you touch the YAML. Read the signal first, patch second.
## ❌ Mistake #2: Fixing the pod but not the source field

**What players try:**
Players patch a live pod, restart it, or try a temporary shell workaround.

**Why it fails:**
If the real issue is in command/args, image, env, config, or memory settings, a manual pod tweak disappears as soon as the controller recreates it.

**Correct approach:**
Apply the fix at the owning manifest level so the pod comes back healthy for the right reason. Objective reminder: The sidecar container has a bad command that causes it to crash immediately — fix the sidecar command so both containers run

**Key learning:**
Always fix the declarative source of truth, not the current container instance.
## ❌ Mistake #3: Ignoring restart history and last termination state

**What players try:**
Players look only at the current container state and miss what happened one restart ago.

**Why it fails:**
The current process may not have failed yet, but the previous one already explains the bug through exit code, reason, or previous logs.

**Correct approach:**
Check previous logs and the last terminated container state before deciding what to change.

**Key learning:**
The last termination often contains the most useful evidence in startup failures.
## ❌ Mistake #4: Stopping after the pod starts once

**What players try:**
Players see one brief Running state and assume the mission is solved.

**Why it fails:**
Some failures return after another restart cycle, a readiness check, or a delayed memory spike.

**Correct approach:**
Let the pod stay up long enough, re-check restart count, then validate. Final check: Both containers Running, restartCount sidecar = 0

**Key learning:**
A stable workload is different from a momentarily lucky workload.

## What To Prove Before You Move On
- The pod is no longer restarting and stays healthy long enough to observe.
- You can explain whether the failure came from image pull, process exit, config, or memory pressure.
- Both containers Running, restartCount sidecar = 0

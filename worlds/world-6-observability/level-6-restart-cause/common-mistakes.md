# Common Mistakes - Level 6: Why Does It Keep Restarting?

## Fastest First Checks
```bash
kubectl get events -n k8smissions --sort-by=.lastTimestamp
kubectl top pods -n k8smissions
kubectl logs <pod> -n k8smissions --previous
```

## ❌ Mistake #1: Relying on one signal only

**What players try:**
Players use just one command in Why Does It Keep Restarting?, such as logs or `kubectl top`, and stop there.

**Why it fails:**
Observability works best when you correlate signals. Events tell you what Kubernetes decided, metrics show pressure, and logs show app behavior.

**Correct approach:**
Combine at least two signals before concluding the root cause.

**Key learning:**
The fastest diagnosis usually comes from signal correlation, not a single favorite command.
## ❌ Mistake #2: Reading the wrong time window

**What players try:**
Players inspect current state only and miss what happened seconds earlier.

**Why it fails:**
Restarts, probe failures, and eviction events are easy to miss if you do not look at previous logs or sorted event history.

**Correct approach:**
Build a timeline for events, logs, and metrics correlation using events, previous logs, and current status together.

**Key learning:**
Incidents are stories over time. A static snapshot is rarely enough.
## ❌ Mistake #3: Debugging the symptom at the wrong layer

**What players try:**
Players jump into a shell before deciding whether the problem is application, probe, node pressure, or missing metrics infrastructure.

**Why it fails:**
That creates noise and wastes time when the cluster already exposes the answer through events, conditions, or controller state.

**Correct approach:**
Start with the cheapest cluster-level evidence, then drill into the container only if the evidence tells you to.

**Key learning:**
Good debugging narrows the layer first, then the exact bug.
## ❌ Mistake #4: Fixing the symptom without updating the mental model

**What players try:**
Players patch the manifest until validation passes but cannot explain why the signal changed.

**Why it fails:**
That makes the next incident feel new even when it is the same class of failure.

**Correct approach:**
After the fix, explain what the signal should look like in a healthy cluster. Success target: Use the validator to confirm the repaired state.

**Key learning:**
Observability is valuable when you can predict healthy vs unhealthy telemetry afterward.

## What To Prove Before You Move On
- You used more than one signal: events, logs, metrics, or probe state.
- You can explain why the chosen signal was the fastest one for this failure.
- Use the validator to confirm the repaired state.

# Why Does It Keep Restarting?

## Situation
Pod shows RESTARTS: 8 over the last hour. No obvious error. Must use events, logs, and describe to find root cause. Root cause: OOMKilled (not CrashLoopBackOff from bad code).

## Successful Fix
kubectl describe pod → find "OOMKilled" in Last State Increase memory limit to 256Mi

## What To Validate
Use the validator to confirm the repaired state.

## Why It Matters
Review how the fix changed the cluster behavior for Why Does It Keep Restarting?.

## Concepts
Exit codes (137=SIGKILL/OOM, 1=crash, 0=clean), kubectl describe lastState, memory profiling

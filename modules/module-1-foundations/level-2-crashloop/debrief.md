# The Infinite Restart

## Situation
Pod is in CrashLoopBackOff. The container exits immediately because the args point to a script that does not exist.

## Successful Fix
Change args to ["/bin/sh", "-c", "sleep 3600"]

## What To Validate
Pod Running for > 30s, restartCount = 0

## Why It Matters
Explain exit codes, restartPolicy (Always/OnFailure/Never), back-off delay

## Concepts
CrashLoopBackOff, args, restartPolicy, exit codes

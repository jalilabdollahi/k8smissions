# Init Loop

## What Was Broken
The init container polled 'non-existent-db-host:5432' in an infinite loop. Since the host doesn't exist, it ran forever. The main container never started because init containers must all succeed first.

## The Fix
Fix the init container command to exit 0, or point it to the actual DB host.

## Why It Matters
Init containers run sequentially before the main container starts. They're for setup tasks: schema migration, configuration generation, dependency waiting. Common pattern: wait for a service port to open before starting the app.

## Pro Tip
kubectl logs <pod> -c <init-container-name> shows init container output. kubectl describe pod shows Init:0/1 for example which means 0 of 1 init containers have completed.

## Concepts
init containers, InitCrashLoopBackOff, sequencing, dependency waiting, pod phases

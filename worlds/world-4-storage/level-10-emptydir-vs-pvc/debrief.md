# Data Lost on Restart

## Situation
App writes user uploads to an emptyDir volume. On pod restart, all files are gone. Must switch to a PVC for persistence.

## Successful Fix
Replace emptyDir with PVC-backed persistent volume

## What To Validate
Use the validator to confirm the repaired state.

## Why It Matters
Review how the fix changed the cluster behavior for Data Lost on Restart.

## Concepts
emptyDir lifecycle (tied to pod), PVC lifecycle (independent), ephemeral vs persistent storage, when to use each

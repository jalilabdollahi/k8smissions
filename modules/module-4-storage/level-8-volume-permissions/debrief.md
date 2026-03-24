# Permission Denied

## Situation
Pod mounts a volume but crashes with "Permission denied" trying to write. Container runs as uid 1000, volume owned by root.

## Successful Fix
Add securityContext.fsGroup: 1000 to pod spec

## What To Validate
Use the validator to confirm the repaired state.

## Why It Matters
Review how the fix changed the cluster behavior for Permission Denied.

## Concepts
fsGroup, runAsUser, runAsGroup, volume ownership, securityContext at pod vs container level

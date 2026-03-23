# Data Deleted!

## Situation
PV had reclaimPolicy: Delete. When devs deleted the PVC, the PV and all data were wiped. Must recreate with Retain.

## Successful Fix
Patch PV reclaimPolicy to Retain kubectl patch pv <pv-name> -p '{"spec":{"persistentVolumeReclaimPolicy":"Retain"}}'

## What To Validate
Use the validator to confirm the repaired state.

## Why It Matters
Review how the fix changed the cluster behavior for Data Deleted!.

## Concepts
Reclaim policies (Delete, Retain, Recycle), data safety, PV release lifecycle, production data protection

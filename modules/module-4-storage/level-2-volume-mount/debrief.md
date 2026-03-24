# Wrong Mount Path

## Situation
App crashes because it reads config from /app/config, but volumeMount path is set to /config.

## Successful Fix
Change mountPath to /app/config

## What To Validate
Use the validator to confirm the repaired state.

## Why It Matters
Review how the fix changed the cluster behavior for Wrong Mount Path.

## Concepts
volumeMounts, mountPath, subPath, volume definitions, container filesystem

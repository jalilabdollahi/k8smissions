# Ghost Patch

## What Was Broken
The Kustomize patch referenced `name: backend-api` but the Deployment's name is `api-server`. Kustomize applies patches by matching kind/name/namespace — no match means the patch is silently skipped. No error is shown.

## The Fix
Fix both the `metadata.name` inside the patch YAML and the `target.name` in the kustomization.yaml to match the actual Deployment name (`api-server`).

## Why It Matters
Kustomize is declarative and silent on mismatches — this is a feature (you can apply overlays that partially match) but also a debugging trap. Always verify applied output with `kubectl kustomize ./overlay` to see the rendered YAML before applying.

## Pro Tip
Use `kubectl kustomize . | kubectl diff -f -` to preview what will change before applying. This shows exactly what Kustomize would modify vs current cluster state.

## Concepts
Kustomize, patch target, strategic merge patch, overlay, dry-run

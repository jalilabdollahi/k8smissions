# Full Pipeline Down

## What Was Broken
Three independent failures each blocking the pipeline: (1) non-existent image tag, (2) required param with no default causing TaskRun validation failure, (3) SA lacking RBAC.

## The Fix
Fix systematically: start with the error that occurs earliest (image pull), then param validation, then RBAC.

## Why It Matters
Multi-failure debugging requires systematic triage: categorize by component (image, config, RBAC), fix in order of dependency, verify each fix before moving to the next.

## Pro Tip
When debugging a broken pipeline: check the TaskRun status (kubectl get taskruns -n <ns>), then describe the youngest TaskRun, then check the pod events, then check the pod logs.

## Concepts
Tekton, debugging, systematic triage, image, RBAC, params

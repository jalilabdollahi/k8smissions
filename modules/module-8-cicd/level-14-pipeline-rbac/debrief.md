# Pipeline Locked Out

## What Was Broken
The trigger-sa ServiceAccount had no permissions to create PipelineRuns. The EventListener received webhook events but couldn't trigger pipeline execution due to RBAC denials.

## The Fix
Create a Role that grants access to Tekton CRD resources in the tekton.dev API group, then bind to the SA.

## Why It Matters
Tekton resources are in the tekton.dev API group. Regular Kubernetes RBAC roles targeted at '' (core) or 'apps' groups won't help. Specify apiGroups: ['tekton.dev'] in the role rules.

## Pro Tip
Use 'kubectl api-resources | grep tekton' to see all Tekton resource types and their API groups.

## Concepts
Tekton, RBAC, PipelineRun, tekton.dev API group, EventListener

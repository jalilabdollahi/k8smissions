# Build Corruption

## What Was Broken
Multiple PipelineRuns shared the same PVC. Concurrent runs wrote to the same paths, corrupting each other's build state. CI became flaky and unreliable.

## The Fix
Use volumeClaimTemplate in PipelineRun specs to provision a fresh PVC per run. The PVC is automatically deleted when the PipelineRun is deleted.

## Why It Matters
volumeClaimTemplate is the recommended pattern for Tekton workspaces — each run gets isolated storage. The auto-created PVC is named <pipelinerun-name>-<workspace-name>.

## Pro Tip
Clean up old PVCs with: kubectl delete pvc -l tekton.dev/pipelineRun -n k8smissions --field-selector=status.phase=Succeeded

## Concepts
Tekton, workspace, volumeClaimTemplate, PVC isolation, concurrent pipelines

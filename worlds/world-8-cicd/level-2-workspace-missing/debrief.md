# No Workspace

## What Was Broken
The PipelineRun had empty workspaces: []. The Pipeline declared a 'source' workspace but no binding was provided. Tekton requires all declared workspaces to be bound before execution.

## The Fix
Add a workspace binding to the PipelineRun spec. For temporary storage use emptyDir. For persistent data between runs, use a PVC.

## Why It Matters
Tekton workspaces are how Tasks share data. An emptyDir is deleted when the run finishes. Use a PVC if you need artifacts after the run.

## Pro Tip
List all workspace declarations in a Pipeline: kubectl get pipeline <name> -o jsonpath='{.spec.workspaces[*].name}'

## Concepts
Tekton, workspace, PipelineRun, emptyDir, PVC binding

## What went wrong

The Pipeline declares `workspaces: [{name: source}]` but the PipelineRun provides `workspaces: []`. Tekton validates all declared workspaces have bindings before creating any TaskRun — no binding means the run is rejected immediately.

## Fix

```yaml
spec:
  pipelineRef:
    name: build-pipeline
  workspaces:
  - name: source
    emptyDir: {}
```

For persistent artifacts across runs, use a PVC instead:
```yaml
  workspaces:
  - name: source
    persistentVolumeClaim:
      claimName: build-pvc
```

## Why this matters

Workspaces are Tekton's mechanism for passing files between Tasks in a Pipeline. Each Task that needs a file (cloned source, compiled binary, test report) declares a workspace; the Pipeline wires them together; and the PipelineRun provides the actual storage. `emptyDir` is ephemeral (lives only for the run's pod lifetime) and works for same-node Tasks. For Tasks that may run on different nodes, you need a PVC with `ReadWriteMany` access mode.
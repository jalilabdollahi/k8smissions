## What went wrong

All PipelineRuns share `shared-build-pvc`. When two runs check out source code simultaneously, they write to the same paths, overwriting each other. Build outputs are mixed. Tests fail nondeterministically. This is a classic shared-mutable-state concurrency bug.

## Fix

```yaml
spec:
  pipelineRef:
    name: ci-pipeline
  workspaces:
  - name: source
    volumeClaimTemplate:
      spec:
        accessModes:
        - ReadWriteOnce
        resources:
          requests:
            storage: 1Gi
```

`volumeClaimTemplate` tells Tekton to create a new PVC for each PipelineRun, named automatically (e.g., `pvc-ci-run-001-source`). The PVC is deleted when the PipelineRun is pruned.

## Why this matters

Shared PVCs between concurrent pipeline runs require external locking (which Tekton does not provide). The `volumeClaimTemplate` pattern is the correct solution — each run gets its own isolated PVC, there is no contention, and cleanup is automatic. Use `ReadWriteOnce` when all Tasks in a run execute on the same node; use `ReadWriteMany` (NFS, CephFS) when Tasks may spread across nodes. The trade-off: `volumeClaimTemplate` provisions a new PVC per run, which means no build cache sharing between runs — combine this with a separate `cache` workspace bound to a shared PVC for cache files.
## What went wrong

The `maven-build` Task declares two workspaces: `source` (for the code) and `cache` (for `~/.m2`). The TaskRun only binds `source`. Without the `cache` binding, Maven sees no local repository on startup and downloads all dependencies from the internet on every run.

## Fix

```yaml
spec:
  taskRef:
    name: maven-build
  workspaces:
  - name: source
    emptyDir: {}
  - name: cache
    persistentVolumeClaim:
      claimName: maven-cache-pvc
```

## Why this matters

Build caches are one of the most impactful CI performance improvements available. Maven's `~/.m2` repository, npm's `node_modules`, pip's wheel cache — once downloaded, these should be persisted across runs. The pattern: a Task declares a workspace for the cache directory; the PipelineRun binds it to a PVC with `ReadWriteOnce`; the Task mounts it to the tool's cache path. Build time goes from 15 minutes to under 1 minute once the cache is warm. The only caveat: don't share a `ReadWriteOnce` PVC between concurrent runs (see level 15).
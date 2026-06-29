## What went wrong

In Tekton, `spec.tasks` tasks only run when their `runAfter` dependencies succeed. When `build` fails, `cleanup` (which has `runAfter: [build]`) is skipped — exactly like a skipped `catch` block. Temporary resources pile up with each failed build.

## Fix

```yaml
spec:
  tasks:
  - name: build
    taskRef:
      name: build-task
  finally:
  - name: cleanup
    taskRef:
      name: cleanup-task
```

Tasks in `spec.finally` cannot have `runAfter` (they have no ordering relative to each other) and they always run — even if the main pipeline is cancelled.

## Why this matters

`spec.finally` is Tekton's equivalent of a `finally` block in a try/catch/finally pattern. It guarantees execution regardless of whether the main task DAG succeeded, failed, or was cancelled. Common uses: sending a Slack notification with the pipeline result, cleaning up temporary namespaces, releasing a distributed lock, or uploading test reports to a storage bucket. Without `finally`, cleanup logic that depends on a successful prior step is unreliable and leads to resource leaks.
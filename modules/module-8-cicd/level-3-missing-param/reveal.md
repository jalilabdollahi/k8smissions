## What went wrong

The Task `image-push` declares a required parameter `IMAGE` with no `default` value. Required parameters must be supplied by the caller. With `params: []` in the TaskRun, Tekton's admission validation rejects the run before any pod is created.

## Fix

```yaml
spec:
  taskRef:
    name: image-push
  params:
  - name: IMAGE
    value: registry.example.com/myapp:v1.0.0
```

## Why this matters

Tekton parameters work like function arguments: a Task declares what inputs it needs, and the caller (TaskRun or Pipeline) supplies the values. Parameters without a `default` are mandatory — this is how Task authors express that the caller must make an explicit choice (like which image to push). Parameters with a `default` are optional overrides. Tekton validates all required params at admission time rather than at runtime, which means you get a clear error message immediately rather than a cryptic script failure minutes into the run.
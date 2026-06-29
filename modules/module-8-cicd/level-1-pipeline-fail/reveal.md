## What went wrong

The Tekton Task step uses `image: golang:99.9-nonexistent`. Before any step script runs, Kubernetes must pull the container image. If the image doesn't exist in the registry, the pod enters `ErrImagePull` → `ImagePullBackOff` and no step ever executes.

## Fix

```yaml
spec:
  steps:
  - name: build
    image: golang:1.21
    script: |
      #!/bin/bash
      echo "Building..."
      go build ./...
```

## Why this matters

In Tekton, each step runs in its own container within the same pod. The pod is not considered running until all step images have been pulled. A single bad image reference in any step causes the entire TaskRun to fail at the pod scheduling phase — before the pipeline even starts. Always pin image tags in CI steps (as in all production containers) and test image references with `docker pull` locally before committing them to a pipeline definition.
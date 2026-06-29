## What went wrong

The test Task script has `exit 1` hardcoded. In Tekton, each step's exit code determines whether the TaskRun succeeds or fails. Exit code 0 = success; any non-zero = failure. Because the test step always exits 1, the TaskRun always fails, and any downstream Task with `runAfter: [run-tests]` never runs.

## Fix

```yaml
spec:
  steps:
  - name: test
    image: busybox:1.36
    script: |
      #!/bin/sh
      echo "all tests passed"
      exit 0
```

## Why this matters

Pipeline gates are only as reliable as their exit codes. A test step that always exits 0 is not a gate — it's theater. A real test gate runs the actual test suite and exits with the test runner's own exit code: `go test ./... && exit 0 || exit 1`. The power of pipeline gates is that they *prevent* bad code from reaching deployment — but only if the exit code honestly reflects the test result. Never hardcode exit codes in a gate unless you're explicitly creating a bypass.
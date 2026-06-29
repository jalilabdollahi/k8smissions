## What went wrong

Tekton result variable syntax: `$(tasks.<task-name>.results.<result-name>)`. The result name must exactly match the name declared in the Task's `spec.results`. The build Task declares `name: imageDigest` but the Pipeline references `image-digest` — one character difference (hyphen vs camelCase). Tekton resolves unmatched result references to an empty string without error.

## Fix

```yaml
params:
- name: IMAGE_DIGEST
  value: $(tasks.build.results.imageDigest)
```

## Why this matters

Tekton results are the primary mechanism for passing data between Tasks in a Pipeline — image digests, git commit SHAs, test counts, file paths. The result name is a contract between the producer Task and the Pipeline. When names drift (due to renaming, copy-paste errors, or case inconsistencies), the consumer silently receives an empty value. Always verify result names with `kubectl get task <name> -o yaml | grep -A5 results` and test pipelines with debug logging to see what values params actually receive.
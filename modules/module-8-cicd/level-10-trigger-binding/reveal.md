## What went wrong

GitHub's push webhook payload has `head_commit.id` for the SHA of the pushed commit — not `commits[0].sha`. Tekton Triggers uses JSONPath-like `$(body.field.path)` syntax to extract values from the webhook body. When the path doesn't match, the value silently resolves to an empty string and the pipeline runs with no git revision.

## Fix

```yaml
spec:
  params:
  - name: git-revision
    value: $(body.head_commit.id)
  - name: git-repo-url
    value: $(body.repository.clone_url)
```

## Why this matters

Webhook payload structures differ between providers: GitHub uses `head_commit.id`, GitLab uses `checkout_sha`, Bitbucket uses `push.changes[0].new.target.hash`. Always consult the provider's webhook documentation and test with a real payload before deploying a TriggerBinding. Use `kubectl port-forward svc/el-<eventlistener> 8080` and a tool like `curl` to send a sample payload and inspect what the EventListener does with it.
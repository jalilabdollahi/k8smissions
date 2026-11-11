The receiver maps `revision` from `body.head_commit.sha`, a key GitHub does not send (the commit SHA is `head_commit.id`), so the param is empty and `clone-at` refuses to run. The receiver also loads `binding.json` only once, at start-up.

1. `kubectl logs deploy/hook` shows `binding: body.head_commit.sha not found in payload, param revision left empty`.
2. Edit ConfigMap `hook-binding`: set `"revision": "body.head_commit.id"` (keep `repo-url` as it is).
3. `kubectl rollout restart deployment/hook`: the running pod still holds the old mapping in memory.
4. `kubectl rollout status deployment/hook`, then a new push creates a run that checks out the pushed commit.

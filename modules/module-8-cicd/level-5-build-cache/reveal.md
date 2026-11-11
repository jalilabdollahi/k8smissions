The cache volume is bound to the run, but nothing connects it to the Task, and the step writes its dependencies to `$HOME`, which is private to each pod.

1. Log of `resolve`: `cache workspace bound: false`.
2. Patch Pipeline `inventory-build`: give the `compile` task `workspaces: [{name: cache, workspace: cache}]`.
3. Edit Task `compile`: `DEPS="$(workspaces.cache.path)/inventory-deps"` in both steps.
4. Run the Pipeline twice with the same claim: the second run prints "dependencies restored from cache" and has `cache-hit` = true.

Mapping alone is not enough: with the step still writing to `$HOME`, the claim is mounted and stays empty.

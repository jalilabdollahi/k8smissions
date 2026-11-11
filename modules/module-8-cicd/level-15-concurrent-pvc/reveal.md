All runs mount the same claim and write `shop.tar` at its root, so concurrent builds overwrite one another's archive between `package` and `verify`. The claim must stay (the runs reference it by name), so isolate inside it.

1. `kubectl edit pipeline build-shop`.
2. Under both tasks' `workspaces` entries add `subPath: $(context.pipelineRun.name)`; each run now reads and writes `<claim>/<run name>/shop.tar`.
3. Three concurrent runs now each verify their own archive.

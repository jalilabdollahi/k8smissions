**Only mapping the workspace.** After the Pipeline fix the log shows `cache workspace bound: true`, but the dependencies are still written under `$HOME`, so every run is a miss. The files have to land under the workspace path.

**Making the workspace required in the Task.** Removing `optional: true` makes a missing mapping an error, which is a good guard, but it does not connect anything by itself.

**Judging by the PVC.** `build-cache` is Bound and was passed to the seeded run, so it looks used. Whether it is mounted into the Task pod and written to is only visible in the step log and the TaskRun's `spec.workspaces`.

**Creating the run again without changing the Task.** `notes-0714` failed because of how the Task is written, so every new run fails the same way. Read the logs of the failing step before starting anything.

**Writing the file to another private path.** Moving it from `/tmp` to `/root` or `/home` fails the same way: those directories are part of each step's own filesystem. Use a path Tekton shares between steps, preferably the declared result.

**Fixing `publish` only.** If `publish` reads the file but nothing writes the result, the run can turn green while the result `version` stays empty. Check the TaskRun's `.status.results`, not just the run's colour.

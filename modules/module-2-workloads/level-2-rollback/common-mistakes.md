## Deleting the failing pods

The ReplicaSet recreates them from the same broken template and they fail the same way. The template, not the pods, is wrong.

## Running `rollout undo` twice

The first undo fixes the problem. Checking and running it again goes back to revision 3, because undo toggles between the two newest revisions. Use `--to-revision` when you want a specific one.

## Deleting the Deployment and re-creating it

It "works" only if you remember the right manifest, and it throws away the revision history. The validator checks that the history survives.

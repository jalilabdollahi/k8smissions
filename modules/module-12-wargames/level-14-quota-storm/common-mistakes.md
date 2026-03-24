# Common Mistakes — Quota Flood

## ❌ Deleting pods one by one
Use `kubectl delete pod -l job=ci-test` to delete by label in one command.

## ❌ Increasing the quota instead of cleaning up
More quota doesn't fix the underlying CI bug.

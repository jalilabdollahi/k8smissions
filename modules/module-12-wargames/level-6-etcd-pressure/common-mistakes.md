# Common Mistakes — etcd Pressure

## ❌ Deleting one by one
Use label selectors or awk piping for bulk deletes.

## ❌ Not labelling objects at creation time
If objects don't have consistent labels, bulk cleanup is much harder.

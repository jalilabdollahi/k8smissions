# Common Mistakes — Orphaned Resources

## Mistake 1: Using labels to find and delete orphans manually

**Wrong approach:** Running kubectl delete -l managed-by=my-operator after CR deletion — manual and error-prone

**Correct approach:** ownerReferences + GC is automatic and correct; use it always for child resource cleanup

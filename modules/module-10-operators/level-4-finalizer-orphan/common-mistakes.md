# Common Mistakes — Orphaned Controller

## Mistake 1: Deleting finalizers manually on every deletion

**Wrong approach:** Force-clearing finalizers bypasses cleanup logic — backend resources will leak forever

**Correct approach:** Fix the operator cleanup code; manual finalizer removal is a break-glass operation

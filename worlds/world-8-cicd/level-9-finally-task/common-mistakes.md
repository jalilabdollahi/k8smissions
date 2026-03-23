# Common Mistakes — Cleanup Skipped

## Mistake 1: Using runAfter to guarantee execution

**Wrong approach:** cleanup runs only after build in runAfter — fails if build fails

**Correct approach:** Use finally for tasks that MUST execute regardless of outcome

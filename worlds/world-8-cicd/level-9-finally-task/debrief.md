# Cleanup Skipped

## What Was Broken
The cleanup Task was in spec.tasks with runAfter: [build]. If build fails, runAfter dependencies are not satisfied and cleanup is skipped. Temporary resources accumulate over time.

## The Fix
Move cleanup to spec.finally. Finally tasks run unconditionally after all pipeline tasks complete or fail.

## Why It Matters
Use finally for: sending notifications, posting test results, cleaning up temp resources, updating PR status. These must run regardless of pipeline outcome.

## Pro Tip
Finally tasks cannot depend on regular tasks via runAfter. They run in parallel after the pipeline's main DAG completes. Use workspace results to pass data from regular tasks to finally tasks.

## Concepts
Tekton, finally, guaranteed execution, cleanup, Pipeline DAG

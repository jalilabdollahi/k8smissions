# Common Mistakes — Init Loop

## Mistake 1: Removing the init container entirely

**Wrong approach:** Deleting the init container — the main app might crash if the DB isn't ready

**Correct approach:** Fix the init container to point to the actual dependency endpoint

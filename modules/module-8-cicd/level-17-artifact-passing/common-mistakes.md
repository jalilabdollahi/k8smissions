# Common Mistakes — Lost Artifact

## Mistake 1: Using workspace to pass data instead

**Wrong approach:** Writing digest to a file in a shared workspace — works but results are the idiomatic way

**Correct approach:** Use results for small scalar values, workspaces for large files/directories

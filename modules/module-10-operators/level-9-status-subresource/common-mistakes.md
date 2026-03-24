# Common Mistakes — Status Not Updating

## Mistake 1: Writing status directly via main resource patch

**Wrong approach:** Using kubectl patch without --subresource=status — may overwrite spec fields accidentally

**Correct approach:** Use the /status subresource endpoint for status; it's the correct pattern and prevents spec-status confusion

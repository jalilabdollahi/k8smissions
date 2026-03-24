# Common Mistakes — System Pod Blocked

## Mistake 1: Using objectSelector instead of namespaceSelector

**Wrong approach:** objectSelector matches on pod labels — system pods don't always have consistent labels to exclude

**Correct approach:** namespaceSelector is more reliable for excluding entire namespaces from webhook coverage

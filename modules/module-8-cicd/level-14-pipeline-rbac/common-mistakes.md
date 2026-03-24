# Common Mistakes — Pipeline Locked Out

## Mistake 1: Creating role for 'pipelineruns' without specifying apiGroups

**Wrong approach:** Setting apiGroups: [""] for pipelineruns — core group has no pipelineruns

**Correct approach:** Always set apiGroups: ["tekton.dev"] for Tekton resources

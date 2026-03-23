# Common Mistakes — Build Corruption

## Mistake 1: Using emptyDir for build workspaces

**Wrong approach:** emptyDir works for isolated runs but data is lost if the Task pod restarts mid-build

**Correct approach:** Use volumeClaimTemplate for persistence within a run, emptyDir only for truly ephemeral data

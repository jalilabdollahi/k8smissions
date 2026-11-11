## Mistakes on this level

- **Labelling the second worker.** Every pod then satisfies the preference, but the label means "restricted data" and now sits on two nodes. The validator requires exactly one labelled node.
- **Raising the preference weight to 100.** It stays a preference; the spread constraint and capacity can still override it.
- **Expecting running pods to move.** Node affinity is `IgnoredDuringExecution`. Editing the template rolls the Deployment; deleting pods or editing a node never re-evaluates an old pod.
- **Cordoning or draining the other worker.** It looks like it works but ties placement to node state instead of the workload, and the validator rejects any cordoned node.

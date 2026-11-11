## Common mistakes

- **Labelling the pods with `kubectl label`.** Endpoints appear immediately and it looks fixed, but a replacement pod comes from the template with the old label. The validator deletes a pod to check exactly this.
- **Changing the Service selector.** It was set by the network team, and the objective says the pods must match it, not the other way round.
- **Editing `spec.selector` of the Deployment.** It is immutable and was not wrong; only the template labels were.
- **Adding `tier: web` but dropping `app: blog`.** The Deployment's selector would no longer match its own pods and the API server rejects the change.

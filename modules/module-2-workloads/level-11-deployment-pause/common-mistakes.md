## Trying `rollout undo`

It refuses while the Deployment is paused, and even without the refusal it would roll back to something the team does not want. Nothing is broken in the template; it is just not being applied.

## Deleting the pods

The ReplicaSet recreates them from the old template, so they come back on 2.3 with the new settings still queued. The pause has to be lifted for pods to change.

## Re-applying the same edits

Re-patching the image or env vars changes nothing while the Deployment is paused, and takes effect only after a resume, when it was already queued anyway.

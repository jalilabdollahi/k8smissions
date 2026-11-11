## Common mistakes

- **`kubectl delete --force --grace-period=0`.** It has no effect on API objects held by finalizers; the delete was already accepted and the object is waiting on the finalizer.
- **Applying the new ConfigMap over the old one.** The object is being deleted: an update cannot clear the deletion mark, and `owner=billing` on a Terminating object is still going to vanish.
- **Editing only the data.** Changing `owner` on the Terminating object does not bring it back; the validator wants an object that is not being deleted.
- **Removing the finalizer without looking.** Know who owns it. Here the operator is gone, so nothing is lost; with a live controller you would be skipping its cleanup.

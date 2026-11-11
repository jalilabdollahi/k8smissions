**What was broken.** The Application `payments-sandbox` owned the namespace itself. Deleting it (with the Argo CD resources finalizer) deleted the Namespace, and the Application waits until it is gone. The namespace stayed in `Terminating` with nothing blocking in it: an aggregated API, `v1beta1.reports.example.io`, was registered, but the Service behind it has no pods. To empty a namespace, Kubernetes must list every resource type, and that group could not be queried, so the namespace controller kept retrying and never removed the namespace.

**The evidence.** The namespace's `status.conditions` (`NamespaceDeletionDiscoveryFailure`) names the group, and `kubectl get apiservice` shows one entry as `False (MissingEndpoints)`. There was no finalizer on any object to remove.

**Why Kubernetes behaved that way.** Deletion must be complete and safe: if the controller cannot see a type, it cannot prove the namespace has no objects of that type, so it waits. A dead APIService also slows discovery and produces warnings in every `kubectl` call.

**The fix.** Remove (or repair) the dead APIService. Do not strip the namespace's finalizer: it unblocks this one namespace and leaves a broken API behind.

**In production.** Aggregated APIs (metrics, custom API servers) are cluster-wide dependencies: alert on APIServices that are not `Available`, and remove their registration before removing the backend.

**Commands worth remembering.**
- `kubectl get apiservice` and `kubectl describe apiservice NAME`
- `kubectl get ns NAME -o jsonpath='{.status.conditions}'`
- `kubectl api-resources` (prints errors for broken groups)

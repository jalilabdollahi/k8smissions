**Removing the namespace's finalizers with `kubectl replace --raw`.** The namespace disappears, but the APIService stays broken and the next namespace deletion hangs in the same way. The objective checks that no API service is unavailable.

**Looking for a stuck object inside the namespace.** Nothing in it holds the deletion: pods, PVCs and custom resources are gone or have no finalizers. The blocker is outside the namespace.

**Deleting the Application again or stripping its finalizer.** The Application is only waiting for its namespace. Removing its finalizer leaves the namespace stuck and the quota counted.

**Deleting `keep-me` or other namespaces while looking around.** It must stay as it is, and the same pod must keep running.

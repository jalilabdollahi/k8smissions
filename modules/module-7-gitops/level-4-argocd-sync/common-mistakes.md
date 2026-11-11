**Only refreshing the Application.** `argocd.argoproj.io/refresh=hard` makes Argo re-read Git and re-compare, but it does not run a sync. The Application stays `OutOfSync` until a sync operation is requested.

**Fixing the namespace and waiting.** After the namespace exists, the Application does not retry on its own because sync is manual. Request a sync (patch an `operation` onto the Application) or the status will not change.

**Putting `CreateNamespace=true` only in the Application spec and expecting the old operation to pick it up.** The failed operation is finished; you need a new one. When you start it with a patch, include the option in the operation too, or create the namespace by hand, so the result does not depend on how the sync was started.

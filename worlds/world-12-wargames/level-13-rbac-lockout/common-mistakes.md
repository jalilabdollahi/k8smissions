# Common Mistakes — Locked Out

## ❌ Creating a new ServiceAccount instead of fixing the binding
The deployment references app-sa by name. A new SA won't help unless you also update the deployment.

## ❌ Not testing permissions after changes
Always verify with kubectl auth can-i after making RBAC changes.

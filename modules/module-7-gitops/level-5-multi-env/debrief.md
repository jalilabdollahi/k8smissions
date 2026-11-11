**What was broken.** The production Application pointed at `overlays/dev`, and carried an inline `source.kustomize.replicas` override that pinned the Deployment to 1 replica. Argo rendered exactly what it was told, applied it, and reported `Synced` and `Healthy`. Nothing was out of sync; the definition itself was wrong.

**The evidence.** `kubectl get app shop-prod -o yaml` shows `spec.source.path` and the `kustomize` block; setting it beside `shop-dev` shows both read the same path. Rendering `overlays/prod` locally with `kubectl kustomize` shows what production should have looked like (3 replicas, `LOG_LEVEL=info`, limits).

**Why Argo behaved this way.** Argo's sync status compares live state with the manifests rendered from the Application's source; health comes from the resources' own status. Neither knows what you intended. Overrides in `spec.source.kustomize` (images, replicas, patches) are applied after the overlay, which is why the second cause survives the first fix.

**The fix.** Point `source.path` at `overlays/prod` and drop the inline replica override (or set it to the intended count, but then Git is no longer the single source of the number). Automated sync rolls it out; `argocd.argoproj.io/refresh=hard` just makes Argo re-read Git now.

**In production.** Keep overrides in Git, not on the Application, so a diff of the repo shows the whole environment. Review the Application objects themselves with the same care as the manifests, ideally generated from an ApplicationSet.

**Commands worth remembering.**
- `kubectl get app NAME -n argocd -o jsonpath='{.spec.source}'`
- `kubectl kustomize overlays/prod` to preview what an overlay renders
- `kubectl annotate app NAME -n argocd argocd.argoproj.io/refresh=hard --overwrite`

1. `kubectl -n k8smissions get deploy frontend -o yaml` shows `spec.paused: true`, and the template already holds `APP_VERSION=2.4` and `FEATURE_NEW_CART=on`; the pods still run the old template.
2. `kubectl -n k8smissions rollout undo deployment/frontend` is refused with `you cannot rollback a paused deployment`.
3. `kubectl -n k8smissions rollout resume deployment/frontend` lifts the pause; the controller rolls out all queued changes as one new revision.
4. `kubectl -n k8smissions rollout status deployment/frontend` waits until 3 of 3 pods run the new template.

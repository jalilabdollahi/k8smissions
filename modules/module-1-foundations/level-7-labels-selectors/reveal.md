1. `kubectl get endpoints blog` is empty; `kubectl get pods --show-labels` shows `tier=frontend` while the Service selects `tier=web`.
2. Labelling the running pods by hand would help only until they are replaced.
3. `kubectl -n k8smissions patch deployment blog -p '{"spec":{"template":{"metadata":{"labels":{"tier":"web"}}}}}'` changes the template; the rollout replaces the pods with correctly labelled ones.

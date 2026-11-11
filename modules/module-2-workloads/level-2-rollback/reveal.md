1. `kubectl -n k8smissions describe pod <pod>` shows `Failed to pull image "nginx:1.27-alpne"`: the tag is a typo.
2. `kubectl -n k8smissions rollout history deployment/web-app` lists three revisions; revision 3 is the typo.
3. `kubectl -n k8smissions rollout undo deployment/web-app` restores the previous pod template (nginx 1.27-alpine) as a new revision.
4. `kubectl -n k8smissions rollout status deployment/web-app` waits until 4 of 4 pods are available.

`kubectl set image deployment/web-app nginx=nginx:1.27-alpine` gives the same end state.

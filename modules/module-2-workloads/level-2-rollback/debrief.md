## What was broken

A Friday hotfix changed the image of `web-app` to `nginx:1.27-alpne`, a tag that does not exist. The Deployment began a rolling update, the new pods could not pull their image, and the rollout stalled half way.

## The evidence

`rollout status` waited forever, `get pods` showed pods in `ErrImagePull` and `ImagePullBackOff`, and `describe pod` carried the exact failing image name. `rollout history` listed three revisions, the newest being the typo.

## Why Kubernetes behaves this way

A rolling update only removes old pods as new ones become Ready. Because the new pods never did, the surviving old pods kept serving, which is why the shop was slow but not down. The Deployment does not roll back by itself; `progressDeadlineSeconds` merely marks the rollout as failed.

## The fix

`kubectl rollout undo deployment/web-app` re-applies the previous revision's pod template as a new revision. Setting the right image by hand also works. Undoing a second time would go forward to the broken template again, because revisions are swapped, not stacked.

## In production

Pin image tags from CI, not by hand, so typos are caught before the apply. Keep `revisionHistoryLimit` above zero, record a `change-cause`, and have the pipeline run `rollout status` and undo on failure.

## Commands worth remembering

- `kubectl rollout history deployment/<name> --revision=<n>`
- `kubectl rollout undo deployment/<name> --to-revision=<n>`
- `kubectl rollout status deployment/<name> --timeout=60s`

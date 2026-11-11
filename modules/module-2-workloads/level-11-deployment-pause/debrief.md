## What was broken

Someone paused `frontend` to batch several edits, changed the version and a feature flag, and never resumed. The new settings sat in the spec while the pods kept running release 2.3.

## The evidence

`rollout status` did not move, the ReplicaSet history had no new revision, and `get deploy -o yaml` had `paused: true` while the pod template already said `APP_VERSION=2.4`. `rollout undo` answered `you cannot rollback a paused deployment`.

## Why Kubernetes behaves this way

Pausing tells the Deployment controller to stop reconciling the pod template. Edits are saved but ignored, which is what makes it useful for batching: ten edits become one rollout on resume. What a pause does not stop is scaling, because replicas are not part of the template; the app looked alive and the missing rollout was easy to miss.

## The fix

`kubectl rollout resume deployment/frontend`. The controller creates one new ReplicaSet from the current template and rolls it out with the normal strategy.

## In production

Pause is cheap to forget. Add `kubectl rollout status` to the pipeline step that follows an edit, and alert on Deployments whose `observedGeneration` or `updatedReplicas` lag for long. Rolling back first (`undo`) is not possible until you resume.

## Commands worth remembering

- `kubectl rollout pause|resume deployment/<name>`
- `kubectl get deploy <name> -o jsonpath='{.spec.paused}'`
- `kubectl rollout history deployment/<name>`

## What went wrong

`spec.paused: true` is set in the manifest. When a Deployment is paused, the controller records changes to the pod template but does not create any new ReplicaSets or pods. The rollout is frozen indefinitely.

## Fix

In manifest.yaml:

```yaml
spec:
  paused: false
```

## Why this field exists

Pausing is useful when you want to make several changes to a Deployment (update image, change env vars, adjust resources) and only trigger one rollout at the end instead of one per change. The workflow is: pause → apply changes → resume. Leaving a Deployment paused in production is almost always a mistake — but it can be subtle because the Deployment itself looks healthy.
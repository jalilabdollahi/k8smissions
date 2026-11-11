## Scaling the Deployment or deleting a few pods by hand

New pods are scheduled by the same broken constraint, so they land wherever the scores happen to favour. The count may look better for a moment and drift back.

## Pinning the pods with a nodeSelector or a second node

That fixes today's picture and drops the spread rule the team wanted. The constraint is meant to keep working when a node comes and goes.

## Fixing the selector and expecting the existing pods to move

The scheduler only places pods; it never relocates running ones. Here the selector lives in the pod template, so the edit rolls the Deployment. If you fixed it some other way, restart the rollout and check `get pods -o wide` afterwards.

# Status Not Updating

## What Was Broken
Without subresources.status configured, the status subresource doesn't exist. Operators using client.Status().Update() in controller-runtime send requests to the /status endpoint — these are silently ignored when the subresource isn't defined.

## The Fix
Add subresources: status: {} to the CRD version definition.

## Why It Matters
Status subresource separates concerns: spec updates go to the main endpoint (controllers watch for spec changes), status updates go to /status (only the controller should update this). No user can accidentally overwrite operator-managed status.

## Pro Tip
Also enable the scale subresource if your operator manages replicas — it enables kubectl scale and HPA support: subresources: scale: specReplicasPath: .spec.replicas statusReplicasPath: .status.replicas

## Concepts
status subresource, CRD, controller-runtime, status update, operator pattern

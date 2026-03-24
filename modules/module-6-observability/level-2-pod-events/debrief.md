# Read the Events

## Situation
Pod is failing but logs are empty. The issue is an image pull problem only visible in cluster events.

## Successful Fix
kubectl get events -n k8smissions --sort-by='.lastTimestamp' Find the ImagePullBackOff event → fix image reference

## What To Validate
Pod Running

## Why It Matters
Review how the fix changed the cluster behavior for Read the Events.

## Concepts
kubectl events, Event objects, reason/message fields, Normal vs Warning events, event TTL (1 hour default)

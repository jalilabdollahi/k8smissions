# Scheduler Deadlock

## What Was Broken
A ValidatingWebhookConfiguration with failurePolicy: Fail was configured for all pod CREATE operations. The webhook service (validator-svc) was down. Every pod creation attempt timed out waiting for webhook response.

## The Fix
Change failurePolicy to Ignore so that webhook failures don't block resource creation. Or fix/restart the webhook service.

## Why It Matters
failurePolicy: Fail is the secure-by-default choice — if the webhook can't be reached, block the operation. But it's a reliability risk: if the webhook crashes, the entire cluster stops accepting new pods. Use Ignore + alerting for non-critical validation webhooks.

## Pro Tip
Scope webhooks narrowly: use namespaceSelector to apply only to specific namespaces, and objectSelector to target specific pods. Never apply a Fail-policy webhook to kube-system.

## Concepts
ValidatingWebhook, failurePolicy, Fail, Ignore, webhook outage, scheduling block

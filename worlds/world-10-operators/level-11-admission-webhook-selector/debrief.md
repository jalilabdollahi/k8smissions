# System Pod Blocked

## What Was Broken
The MutatingWebhookConfiguration had no namespaceSelector — it intercepted ALL pod creations cluster-wide, including in kube-system. When kube-dns pods needed to restart, the webhook blocked them (or mutated them incorrectly).

## The Fix
Add a namespaceSelector to exclude kube-system, kube-public, and kube-node-lease from webhook coverage.

## Why It Matters
Golden rule: NEVER apply webhooks with Fail policy to kube-system, kube-public, or kube-node-lease. These contain cluster infrastructure (DNS, networking, controllers) that must be immune to webhook failures.

## Pro Tip
Auto-label namespaces for webhook exclusion: kubectl label namespace kube-system webhook.example.com/ignore=true, then use matchExpressions on that label in namespaceSelector.

## Concepts
MutatingWebhook, namespaceSelector, kube-system, DNS failure, webhook scope

# Slow Admission

## What Was Broken
The ValidatingWebhookConfiguration had timeoutSeconds: 30. The webhook service made slow external API calls (policy database) synchronously. Every pod creation blocked for up to 30 seconds before proceeding.

## The Fix
Reduce timeoutSeconds to 5 and optimize the webhook service to use caching for policy lookups.

## Why It Matters
Webhook timeoutSeconds controls how long the API server waits for a webhook response. Default is 10s, max is 30s. Aim for <100ms webhook response time. Cache policy decisions, use connection pooling, avoid synchronous external calls.

## Pro Tip
Webhook performance checklist: in-memory policy cache (TTL 60s), async policy refresh, connection keep-alive, horizontal scaling of webhook service, metrics for p50/p99 latency.

## Concepts
admission webhook, timeoutSeconds, performance, latency, webhook optimization

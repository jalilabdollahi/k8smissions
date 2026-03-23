# Silent Timeout

## What Was Broken
The Istio VirtualService had a 15s timeout. Long-running API operations (file processing) exceeded this limit. Envoy rejected the request with 504 Gateway Timeout after exactly 15s.

## The Fix
Increase timeout to match the expected operation duration. Add retries for transient errors but not for non-idempotent long operations.

## Why It Matters
Service mesh timeout hierarchy: client-side timeout → VirtualService timeout → DestinationRule retries → upstream service timeout. All must be consistent. A 30s client timeout with 15s mesh timeout never reaches 30s.

## Pro Tip
Circuit breaker + timeout: use DestinationRule outlierDetection to circuit-break on consecutive 5xx errors. This prevents cascading failures when a service is slow — fail fast rather than waiting for timeout.

## Concepts
Istio, VirtualService, timeout, service mesh, circuit breaker

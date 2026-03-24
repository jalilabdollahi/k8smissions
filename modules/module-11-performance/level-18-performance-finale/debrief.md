# The Great Slowdown

## What Was Broken
Three independent performance issues: (1) DNS ndots:5 caused 5 lookups per short hostname query, (2) CPU limits equal to requests caused CFS throttling on any burst, (3) maxSurge:0 with 50 replicas serialized all pod updates.

## The Fix
Fix each independently: ndots:2 for DNS, 10x CPU limit for burst capacity, maxSurge:10 for parallel rollout.

## Why It Matters
Performance debugging methodology: profile first, fix bottlenecks in order of impact. DNS issues affect every request. CPU throttling affects specific services. Slow rollouts affect deployment operations but not runtime.

## Pro Tip
Automated performance regression detection: track p99 latency as a deployment metric. Include performance tests in CI/CD. If a deploy increases p99 by >10%, trigger rollback automatically.

## Concepts
DNS ndots, CPU throttling, maxSurge, performance tuning, multi-issue

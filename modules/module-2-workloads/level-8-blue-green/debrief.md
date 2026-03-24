# Blue-Green Gone Wrong

## Situation
Blue-green deployment done. New (green) deployment is healthy but the Service still routes to the old (blue) version.

## Successful Fix
Patch service selector to version: green

## What To Validate
curl to service returns green deployment response

## Why It Matters
Blue-green vs rolling update, cost (double resources), canary as a middle ground

## Concepts
Blue-green strategy, service selectors, zero-downtime switch, rollback by switching selector back

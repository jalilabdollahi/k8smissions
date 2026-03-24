# Database Stampede

## What Was Broken
DB_POOL_SIZE was 1 — each pod created one connection per concurrent request. 10 pods under load created thousands of concurrent connections, exhausting the database's connection limit.

## The Fix
Increase DB_POOL_SIZE to 5-10 per pod. With 10 pods and pool_size=5, max concurrent connections = 50 — well within PostgreSQL's limit.

## Why It Matters
Connection pool sizing formula: max_connections = pods * pool_size. Target 50-80% of DB max_connections. For large deployments, use pgBouncer as a connection proxy to multiplex thousands of app connections into hundreds of DB connections.

## Pro Tip
Kubernetes-native connection pooling: PgBouncer as a sidecar container (per pod) or as a separate deployment. Sidecar: each pod connects to localhost:5432 (pgBouncer), which pools to the real DB — consistent connection management regardless of app framework.

## Concepts
connection pooling, DB connections, pool_size, connection storm, pgBouncer

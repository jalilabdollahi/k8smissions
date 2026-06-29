## What went wrong

`DB_POOL_SIZE: 1` per pod means the entire deployment (10 pods) has a maximum of 10 simultaneous database connections. A connection pool of 1 creates a serialization bottleneck — every request that needs the database must wait for the single connection to be free.

## Fix

```yaml
env:
- name: DB_POOL_SIZE
  value: '5'
- name: DB_POOL_TIMEOUT
  value: '30'
- name: DB_POOL_MAX_OVERFLOW
  value: '10'
```

Total max connections: 10 pods × (5 pool + 10 overflow) = 150 max connections.

## Why this matters

Connection pool sizing is a balance: too small → request queuing and timeouts. Too large → database connection exhaustion (PostgreSQL default max is 100; RDS allows ~3× memory/12.5MB). Rule of thumb: `pool_size × replicas ≤ database max_connections × 0.8`. The `max_overflow` parameter allows temporary burst above `pool_size`, automatically cleaned up when the burst subsides. `pool_timeout` prevents requests from waiting forever — fail fast with a meaningful error is better than cascading timeouts. For very high replica counts, consider PgBouncer as a connection pooler in front of the database.
# Common Mistakes — Database Stampede

## Mistake 1: Increasing DB max_connections

**Wrong approach:** Raising Postgres max_connections to 5000 — taxing for the DB, doesn't fix the root cause

**Correct approach:** Fix the pool size in the app; DB connections are expensive and should be pooled tightly

session-db accepts 20 connections. cart-api opens `DB_POOL_SIZE` (5) per pod: 6 pods need 30, so some pods never fill their pool and never become Ready. A smaller pool such as 3 fixes steady state (18) but a rolling update runs up to 8 pods (`maxSurge: 2`), and 8 x 3 = 24 overflows again.

1. `kubectl logs deploy/cart-api` shows `too many connections`; the db's stats show `active: 20` and a growing `rejected`.
2. `kubectl set env deployment/cart-api DB_POOL_SIZE=2` gives 6 x 2 = 12 steady and 8 x 2 = 16 at the surge peak, both under 20.
3. Equivalent: keep a larger pool and set `maxSurge: 0` so no extra pods exist during an update (6 x 3 = 18; the update then replaces pods in place).
4. Do not lower replicas: the objective needs 6.

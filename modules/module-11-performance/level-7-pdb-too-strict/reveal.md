`orders-api` has 3 replicas and `minAvailable: 3`, so `ALLOWED DISRUPTIONS` is 0. `orders-cache` has 1 replica and `minAvailable: 1`, also 0. `kubectl drain` evicts through the eviction API, which refuses anything that would take a budget below its minimum, so the drain retries forever.

1. `kubectl get pdb` shows `ALLOWED DISRUPTIONS 0` for both.
2. `kubectl patch pdb orders-api --type=merge -p '{"spec":{"minAvailable":null,"maxUnavailable":1}}'` allows one API pod down at a time (two stay up).
3. For `orders-cache`, either scale it to 2 replicas and keep `minAvailable: 1`, or allow its single pod to be evicted with `maxUnavailable: 1` (a short cache gap while it reschedules).
4. Do not delete the budgets: the validator checks that they still select and protect the pods.

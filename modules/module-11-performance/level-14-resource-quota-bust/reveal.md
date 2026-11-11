**Cause.** The quota allows 1500m of CPU requests. `payments-web` reserves 4 x 280m = 1120m and the idle `batch-reprocess` reserves 250m, leaving 130m. The strategy is `maxSurge: 1, maxUnavailable: 0`, so a release needs one extra 280m pod before any old pod may go, which the quota refuses (`exceeded quota: compute`). The rollout waits forever.

**Fixes that work** (any one):
- Size the request to what the pods really use (`kubectl top` shows a few millicores): `kubectl set resources deployment/payments-web --requests=cpu=100m`.
- Take surge out of the picture: `maxSurge: 0, maxUnavailable: 1`.
- Free quota by scaling the idle `batch-reprocess` down (its owner has to agree).

**Not allowed.** Raising `requests.cpu` on the ResourceQuota.

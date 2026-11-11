**Doing the steady-state math only.** 6 pods x 3 = 18 is under 20, so a pool of 3 looks right and the pods become Ready. The next rolling update starts up to 2 extra pods that open their pools while the old ones are still connected, and session-db rejects the overflow. Count the pods that exist at the peak.

**Scaling the Deployment down.** Three replicas x 5 = 15 fits even during an update, but the capacity plan needs 6 replicas and the validator checks for them.

**Raising the database limit.** session-db's limit is a property of the database (memory, file descriptors), not something to bump when a client misbehaves. The objective keeps it at 20.

**Not testing a rollout.** Always run `kubectl rollout restart` and watch the db's `rejected` counter; a fix that holds only until the next deploy is not a fix.

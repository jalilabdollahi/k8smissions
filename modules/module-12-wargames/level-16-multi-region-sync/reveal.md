Three faults, each behind the previous one:

1. Lease `eu-leader` is held by `replicator-7c9`, a pod that no longer exists, with a duration of ten years, so neither live replicator may take it ("standby" in both logs). Delete the Lease (the next replicator creates it) or patch the holder and duration so it counts as expired.
2. `us` has a NetworkPolicy that admits only namespaces labelled `region=eu`; `eu` carries no such label, so replication times out. `kubectl label namespace eu region=eu`. Deleting the policy would open `us` to every namespace.
3. The token Secret in `us` was created with `echo`, so it ends in a newline and the replica refuses the replicator's token (HTTP 401). Recreate it with the exact value from `eu` (no newline) and restart the `us` store, because it reads the Secret as an environment variable at start.

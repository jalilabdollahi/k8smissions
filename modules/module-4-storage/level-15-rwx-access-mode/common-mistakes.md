# Common mistakes: level 15

**Editing `accessModes` on `shared-pvc`.** The API refuses: access modes are immutable on an existing claim. Delete it and create a new one (nothing is stored on it yet).

**Deleting `ingest-data` to free the volume.** It is the volume the old pod holds, and it contains v1's first sealed batch. The check requires `data=ok`, which a fresh empty volume can never give.

**Fixing the claim but not the rollout.** Once `shared-pvc` is single-writer the new pod still cannot start while the old one holds the `ReadWriteOncePod` volume. `kubectl rollout status` keeps waiting. The Deployment must stop the old pod first.

**Setting `strategy.type: Recreate` with a merge patch that leaves `rollingUpdate`.** The API rejects `rollingUpdate` parameters with `Recreate`. Send `"rollingUpdate": null` in the same patch (or edit the object).

**Scaling to 0 and back and calling it done.** It works once, but the next release deadlocks the same way. Fix the strategy.

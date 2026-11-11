**Fixing the `when` and forgetting the Deployment.** The rollback Task now runs, but `kubectl rollout undo` fails with "no rollout history found" and the bad image stays. The run is red twice and nothing is restored.

**Removing the `when` altogether.** Then `rollback` also runs after successful releases and undoes every good deploy. The guard is needed, it just has to compare with a value that exists.

**Raising `revisionHistoryLimit` after the bad release and expecting history.** Revisions are kept from the moment the limit allows them; a release that already ran with limit 0 left none behind. The check performs a good release first, which creates the revision to return to.

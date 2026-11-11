**Pushing the fix and waiting.** The old operation is still `Running`, waiting for a Deployment that cannot become healthy, and a new commit does not interrupt it. Terminate the operation and request a sync.

**Running the migration by hand.** `curl -X POST schema-db/migrate/3` moves the version to 3, but the stuck sync still has its Job in the wrong phase, and the next release deadlocks again. The hook must run from Git.

**Creating the ConfigMap `migrations` with `kubectl`.** The hook may work once, but a clean sync still fails in the next environment, because Git creates that ConfigMap too late.

**Moving the Deployment to a later wave instead of fixing the hook phase.** Waves only order resources inside one phase. A PostSync hook still runs after the Sync phase, and the pods still wait for a migration that has not happened.

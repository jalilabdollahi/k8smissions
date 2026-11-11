## Mistakes on this level

- **Raising `count/pods`.** It would unblock tonight, and the quota is the team's decision: the validator checks it still says 10.
- **Only deleting the old Jobs.** The room appears and `catalog-web` goes green, but with `successfulJobsHistoryLimit: 20` the CronJob will refill the namespace. Bound the history or add a TTL too.
- **Deleting the CronJob or suspending it.** Prices stop syncing; the objective keeps `price-sync` on schedule.
- **Looking for Pending pods.** There are none: the quota refuses pods at creation, so the evidence is in the ReplicaSet events and in `describe quota`.

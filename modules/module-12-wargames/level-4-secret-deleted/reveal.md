1. **The Secret is gone.** New `billing-api` pods stop at `CreateContainerConfigError: secret "db-credentials" not found`, while the old pods keep their environment from the time they started.
2. **The value must be the original one.** The database was not rotated and rejects anything else (`401`, visible in `billing-db` logs). Recover it from a running pod: `kubectl exec <pod> -- printenv DB_PASSWORD`. (`billing-db-engine` holds the database's own copy, too.)
3. **Two key names.** `billing-api` reads key `password`; `invoice-export` reads `DB_PASS` (and the Secret also had `username`). Create `db-credentials` with all of them: the CronJob only fails at night if you forget `DB_PASS`.

`kubectl create secret generic db-credentials --from-literal=username=billing --from-literal=password=$PW --from-literal=DB_PASS=$PW`. The stuck pods retry and the rollout completes; the CronJob can be tested with `kubectl create job --from=cronjob/invoice-export`.

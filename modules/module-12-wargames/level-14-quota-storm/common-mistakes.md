**Cleaning up without changing the retrier.** Deleting the finished Jobs lets `release-v42` start for a moment, but `ci-retrier` adds a Job every ten seconds without a TTL, so the quota is full again within minutes. Give its Jobs a TTL first.

**Deleting every Job in the namespace.** `kubectl delete jobs --all` removes `release-v40` and `release-v41` too, which have to stay for the audit trail. Select by label.

**Stopping at the Job count.** With slots free, `release-v42` exists but its pod is still refused: `flaky-suite` holds 600m of the 1 CPU quota. Delete pods by hand and nothing changes (the Job recreates them or they are refused); stop the Job itself.

**Raising the quota.** It makes the numbers look fine and is rejected here: the quota is a policy the team set, the validator expects it unchanged.

## Silencing it with CRITICAL

The line count drops, but WARN and ERROR lines disappear too. During the next incident they are what you need, and the validator requires them to be present.

## Counting with a single pod's log

`kubectl logs deploy/ledger-api` picks one pod and shows its whole history. Use `--since=1m` and a label selector with `--prefix` so you can compare pods and services over the same window.

## Fixing the wrong Deployment

`ledger-batch` has the correct value and a clean log. Editing it, or scaling `ledger-api` down, leaves the real cause alone; scaling also breaks the replica check.

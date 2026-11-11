## What was broken

`ledger-web` has an init container, `wait-for-db`, that loops on `nc -z ledger-db 5432` and only exits once the database accepts connections. The database Deployment `ledger-db` had been scaled to zero by a cost-saving job, so its Service had no endpoints and the init loop never finished.

## The evidence

`kubectl get pods` showed `Init:0/1` on `ledger-web`: the first of one init containers still running, so no app container. `kubectl logs <pod> -c wait-for-db` repeated `waiting for ledger-db:5432`. `kubectl get endpoints ledger-db` was empty, and `kubectl get deployment ledger-db` showed `0/0`.

## Why Kubernetes behaved this way

Init containers run one after another, each to completion, before any app container starts. A pod whose init container never exits stays in `Init:N/M` forever, with no restart or error, because waiting is exactly what the init container was written to do. Kubernetes does not know the pod depends on another workload; that knowledge lives in the init script.

## The fix

Start the dependency (`kubectl scale deployment ledger-db --replicas=1`). Nothing needs to happen to `ledger-web`: its init container retries every two seconds and passes on its own.

## In production

Make the wait loop log what it waits for and give it a timeout so the pod fails loudly instead of idling for days. Treat a scaled-to-zero dependency as a change to announce, and tag cost-saving actions (here an annotation on the Deployment says what changed and when). Deleting the init container only moves the failure into the page.

## Commands worth remembering

- `kubectl logs <pod> -c <init-container>`
- `kubectl get endpoints <service>`
- `kubectl get pod <pod> -o jsonpath='{.status.initContainerStatuses[*].state}'`

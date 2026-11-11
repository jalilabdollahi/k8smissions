## Common mistakes

- **Deleting the pod or restarting `ledger-web`.** The new pod runs the same init container against the same empty Service and sits in `Init:0/1` again.
- **Removing the init container from the Deployment.** The app starts, but it connects to `ledger-db` on every request and the page says `db: unreachable`, so the check fails.
- **Looking at `kubectl logs <pod>` without `-c`.** An app container that never started has no logs. The information is in the init container's logs.
- **Creating a new Service or pod called `ledger-db` by hand.** Fix the existing Deployment so the Service selects real pods; the check wants a Ready backend behind Service `ledger-db`.

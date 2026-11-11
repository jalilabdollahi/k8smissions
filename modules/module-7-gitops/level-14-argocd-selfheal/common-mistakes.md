**Editing the ConfigMap again, faster.** Self-heal wins every time; the live edit lasts only until Argo's next reconcile. The change must be in Git.

**Turning off automated sync or self-heal.** The edit then stays, but the Application drifts from Git, the check for a new synced commit fails, and the validator tests that manual changes are still reverted.

**Pushing a commit that Argo does not pick up.** The poll interval is three minutes. Refresh the Application with `argocd.argoproj.io/refresh=hard` to see the change now.

**Choosing a timeout that is still too short.** The upstream answers in about 600 ms. Measure it from the probe pod before choosing a number.

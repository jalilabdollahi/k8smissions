**What was broken.** The client-side timeout towards the ledger upstream was 200 ms, but the upstream takes about 600 ms, so `/ping` answered 504. The on-call engineer raised the value in the live ConfigMap, which worked for twenty seconds. The Application has automated sync with self-heal, and the value in Git was still 200, so Argo CD treated the edit as drift and wrote the Git version back. Three attempts, three reverts.

**The evidence.** The Application's `syncPolicy.automated.selfHeal: true`, the sync history with a new operation after every edit, and `managedFields` on the ConfigMap showing the Argo CD controller as the last writer.

**Why Argo behaved that way.** With self-heal, Argo compares the live state with Git whenever a watched resource changes, and re-applies Git when they differ. That is the feature working, not a malfunction: Git is declared to be the single source of truth.

**The fix.** Change the value in Git, push, and let Argo apply it. Because the app reads the ConfigMap on each request, the fix is effective as soon as the sync finishes. Self-heal stays on, so real drift is still reverted.

**In production.** Break-glass edits happen. The sound way is a commit (even an emergency one, with review afterwards), or pausing automation for that one Application for a short, announced window and reverting through Git. Do not leave self-heal off.

**Commands worth remembering.**
- `kubectl -n argocd get app NAME -o jsonpath='{.status.history}'`
- `kubectl get cm NAME -o yaml --show-managed-fields`
- `kubectl -n argocd annotate app NAME argocd.argoproj.io/refresh=hard --overwrite`

**What was broken.** The database password lived in Git as a Secret manifest that Argo CD applies with `selfHeal: true` and `prune: true`. After the DBA team rotated the password, any manual correction of the live Secret was reverted a few seconds later because Git, the source of truth, still held the old value, and `ledger-api` kept sending it to the database gateway.

**The evidence.** The Secret carried Argo's tracking annotation, `kubectl get app -o yaml` showed it as a managed resource, and the revert showed up in the Application's history. A clone of the repo contained `deploy/secret.yaml` with a plain-text password.

**Why Argo behaved this way.** Self-heal compares live state with Git continuously and syncs on drift; prune deletes resources that Argo created but that are no longer in Git. Both are correct for anything Git owns. Removing the manifest alone therefore deletes the live Secret too, and a new pod then fails with `CreateContainerConfigError`. Also, environment variables from a Secret are read when the container starts, so a running pod keeps the old value until it is restarted.

**The fix.** Take the Secret out of Git, create it from outside after Argo has pruned it, and restart the Deployment. Argo only manages objects it tracks, so a Secret created afterwards by hand (or by a secret operator) is left alone. The old password is still in Git history: treat it as burned, which is fine because it was rotated.

**In production.** Use External Secrets Operator, Sealed Secrets or SOPS so the source of truth for a secret is a vault or an encrypted file, not plain text, and let Argo reconcile only the reference to it.

**Commands worth remembering.**
- `kubectl get secret NAME -o yaml` (look at annotations and labels for the owner)
- `kubectl get app NAME -n argocd -o yaml`
- `git rm FILE && git commit && git push`

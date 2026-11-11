**Editing the live Secret again.** `kubectl edit secret ledger-db` or `kubectl patch` works for a few seconds and then self-heal puts the old value back from Git. As long as Git holds the manifest, the live copy cannot differ.

**Deleting `secret.yaml` from Git and stopping there.** With `prune` on, Argo deletes the live Secret, so a new pod cannot start and the old one still carries the old password in its environment. Recreate the Secret outside Git after the prune, and restart the Deployment.

**Switching off self-heal or automated sync.** The Secret then stays as you edit it, but the objective requires automated sync with prune and self-heal to remain on, and the password would still be in the repository for the next person to find.

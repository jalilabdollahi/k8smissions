## Mistakes on this level

- **Binding the Role to `default`.** The app starts working, but every pod in the namespace can now read the flags, and the validator checks that `default` still cannot.
- **Stopping after the first fix.** The 403 disappears and a new crash replaces it. Read the new log line instead of assuming the switch failed: the token is not mounted because automount is disabled on the ServiceAccount.
- **Granting `flags-reader` a wildcard or `secrets` to "be safe".** The Role was already enough for one ConfigMap. Extra verbs or resources fail the least-privilege checks.
- **Editing the running pod.** `serviceAccountName` cannot be changed on a live pod; change the Deployment template so the ReplicaSet creates new pods.

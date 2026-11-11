## Mistakes on this level

- **Looking for pods.** None exist; the denial is an event on the ReplicaSet.
- **Hardening the web container only.** The init container is checked as well, and the rollout keeps failing with the same message naming `prepare`. Fix every container.
- **Lowering the namespace to `baseline` or `privileged`.** The pods start, but the validator requires `enforce=restricted` and still tests that a privileged pod is rejected.
- **Setting `runAsNonRoot: true` without a user the image can use.** If the image user is a name rather than a number the kubelet refuses with `CreateContainerConfigError`. Set a numeric `runAsUser`.

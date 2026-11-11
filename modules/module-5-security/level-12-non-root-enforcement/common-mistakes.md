## Mistakes on this level

- **Deleting or loosening the policy.** The rollout works, but the platform team's rule is gone for the whole namespace; the validator checks that a root pod is still rejected.
- **Stopping at pod-level `runAsNonRoot: true`.** The web container starts, the sidecar does not: `CreateContainerConfigError`. The flag is a promise the kubelet verifies against the image's real UID.
- **Using a user name such as `runAsUser: nobody`.** The field is an integer. Use a non-zero number such as 101.
- **Setting `runAsNonRoot: false` or `runAsUser: 0` to see what happens.** Both are rejected or fail the UID check; the goal is a real non-zero UID in both containers.

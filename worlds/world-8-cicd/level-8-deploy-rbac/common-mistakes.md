# Common Mistakes — Blocked Deploy

## Mistake 1: Giving cluster-admin to the pipeline SA

**Wrong approach:** ClusterRoleBinding to cluster-admin for convenience — massive security hole

**Correct approach:** Grant only the verbs and resources the pipeline actually needs

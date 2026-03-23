# Common Mistakes — Permission Denied in Controller

## Mistake 1: Giving the operator cluster-admin

**Wrong approach:** Adding ClusterRoleBinding to cluster-admin — works but is a massive security risk

**Correct approach:** Grant least privilege: only the exact resources and verbs the operator actually needs

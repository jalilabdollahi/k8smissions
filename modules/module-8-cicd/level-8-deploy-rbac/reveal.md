`deploy-sa` is bound in the wrong namespace, and the Role it is bound to does not cover Services.

1. The step log: `deployments.apps is forbidden: User "system:serviceaccount:k8smissions:deploy-sa" cannot get resource "deployments" ... in the namespace "shop-staging"`.
2. The Role and RoleBinding exist in `k8smissions`; they have no effect in `shop-staging`.
3. Create a Role in `shop-staging` with `get/list/watch/create/update/patch` on `deployments` (apiGroup `apps`) and on `services` (core group), and a RoleBinding to ServiceAccount `deploy-sa` of namespace `k8smissions`.
4. Start a new run as `deploy-sa`: Deployment and Service are applied and the rollout completes.

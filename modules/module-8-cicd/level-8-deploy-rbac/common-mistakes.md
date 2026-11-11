**Editing the Role in the pipeline's namespace.** Adding Services to `storefront-deployer` in `k8smissions` changes nothing for `shop-staging`; the permission has to be granted where the objects are applied.

**Granting only Deployments.** After the namespace is right the run fails again, now on Services: they belong to the core API group, not `apps`. Check each kind the manifest contains with `can-i` before running.

**Binding `cluster-admin`.** The run turns green, but `deploy-sa` can now read Secrets and change `shop-prod`, which the objective forbids. A namespaced Role with the few verbs the step uses is enough.

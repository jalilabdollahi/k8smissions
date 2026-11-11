## What was broken

Task `deploy` applies a Deployment and a Service into `shop-staging` as ServiceAccount `deploy-sa`, which lives in the pipeline's namespace `k8smissions`. The only Role and RoleBinding for it were created in `k8smissions` as well, so in `shop-staging` the account could do nothing. Once Deployments were permitted there, Services were still missing from the rules.

## The evidence

The step log carried the Kubernetes error with the user, verb, resource and namespace. `kubectl auth can-i ... --as=system:serviceaccount:k8smissions:deploy-sa` reproduced it without running the pipeline, and `kubectl get role,rolebinding -A` showed where the existing objects were.

## Why Kubernetes behaved this way

RBAC is additive and namespaced: a RoleBinding grants the permissions of its Role only in the namespace where the RoleBinding is; its subject can be a ServiceAccount from any namespace. Rules match on apiGroup and resource: `deployments` are in `apps`, `services` in the core group. `kubectl apply` reads before it patches, so `get` is needed with `create` and `patch`; `rollout status` needs `list` and `watch`. `kubectl apply -f` processes objects in file order, which is why the Service failure came second.

## The fix

A Role and RoleBinding in `shop-staging` with exactly those verbs on those two resources. `cluster-admin` would have worked too, and would also have given the pipeline Secrets and `shop-prod`.

## In production

Give each pipeline its own ServiceAccount per target namespace and review them like code. `kubectl auth can-i --list --as=...` shows everything an account can do; run it after the change.

## Commands worth remembering

- `kubectl auth can-i VERB RESOURCE -n NS --as=system:serviceaccount:NS:NAME`
- `kubectl auth can-i --list -n NS --as=...`
- `kubectl create rolebinding NAME --role=ROLE --serviceaccount=NS:SA -n TARGET`

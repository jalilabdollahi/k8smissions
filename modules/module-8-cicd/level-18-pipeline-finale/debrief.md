## What was broken

Three faults in a row, each only visible once the previous one was fixed. `clone` asked for branch `main`, but the repository has `master`. The `push` step used `crane append` without `--insecure` against a registry that only speaks HTTP. And the RoleBinding that lets `deploy-sa` work in `payments-prod` named the ServiceAccount in the wrong namespace, so it bound a ServiceAccount that does not exist and `deploy-sa` had no rights there.

## The evidence

The first TaskRun log ended with `fatal: Remote branch main not found in upstream origin`, which also rules out credentials: Git authenticated and then looked for the branch. The second showed a TLS or HTTP-versus-HTTPS error from the registry client. The third was a Forbidden from `kubectl apply` naming `deploy-sa` and `payments-prod`; `kubectl auth can-i --as=system:serviceaccount:k8smissions:deploy-sa` answered `no`, and the RoleBinding's subject carried another namespace.

## Why each happened

Tekton runs Tasks in dependency order, so a Task that is never reached cannot show its problem. Clients like crane assume TLS unless told otherwise. An RBAC subject of kind ServiceAccount is identified by name and namespace together: the binding looked right, matched nothing and gave no warning.

## The fix

Default `revision` to `master`; pass `--insecure` for the in-cluster registry; correct the subject namespace. The Role was already right, and the validation confirms nothing widened it: `deploy-sa` still cannot read Secrets or change anything in `k8smissions`.

## In production

Use the repository's default branch dynamically (or a pinned tag), put registries behind TLS (or configure the runtime's insecure registry list instead of flags), and verify bindings with `can-i` rather than by reading YAML.

## Commands worth remembering

- `kubectl logs -l tekton.dev/pipelineRun=NAME --all-containers`
- `git ls-remote URL`
- `kubectl auth can-i --list --as=system:serviceaccount:NS:SA -n TARGET`

Three independent faults, each hidden behind the one before it:

1. `clone`: the Pipeline default `revision: main`, but the repository's only branch is `master` (`git clone --branch main` fails with "Remote branch main not found"). Set the default to `master`. The Git credentials were never the problem.
2. `push`: the registry at `registry.k8smissions.svc.cluster.local:5000` is plain HTTP, and `crane append` defaults to HTTPS, so the push fails with an HTTP-versus-HTTPS error. Add `--insecure` to the command.
3. `deploy`: RoleBinding `deploy-sa-payments` in `payments-prod` names subject `deploy-sa` in namespace `ci-system`, a ServiceAccount that does not exist. Change the subject namespace to `k8smissions`; the Role itself is fine. Do not grant more than the Role gives.

Start a new run (as `deploy-sa`) after each fix to meet the next failure.

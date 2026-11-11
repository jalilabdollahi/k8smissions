**Stopping after `create`.** The child run appears, the Task then fails with a second Forbidden on `get`/`watch`, and the run looks like it is flaky. `kubectl wait` needs read access to the run it waits for.

**Using `apiGroups: [""]`.** Tekton resources are not in the core group. A rule written for `pipelineruns` without `tekton.dev` matches nothing, and `can-i` stays at `no`.

**Binding a broad role.** `cluster-admin`, a ClusterRole with `*`, or `tekton.dev` wildcards make the nightly run pass, and the dispatcher can then delete Pipelines or create TaskRuns. The check asks for exactly the job's permissions.

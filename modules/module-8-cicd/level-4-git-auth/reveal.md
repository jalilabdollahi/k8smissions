Two independent defects, either one alone leaves the clone unauthenticated:

1. The run uses ServiceAccount `default`; the Secret is attached to `ci-runner`, so Tekton never mounts it. Start the new run with `taskRunTemplate.serviceAccountName: ci-runner`.
2. The Secret's `tekton.dev/git-0` annotation says `https://gitserver.gitops-git.svc.cluster.local`, but the clone URL is `http://gitserver.gitops-git.svc.cluster.local:8080/...`. Credentials are matched by scheme, host and port, so none are written. Fix it: `kubectl annotate secret ci-git --overwrite tekton.dev/git-0=http://gitserver.gitops-git.svc.cluster.local:8080`.

Then create the new PipelineRun; `clone` returns the HEAD commit of `payments-ci`. Keep the Secret as `kubernetes.io/basic-auth`; do not put the password into the URL.

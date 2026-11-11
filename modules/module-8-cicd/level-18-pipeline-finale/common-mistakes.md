**Rotating or recreating the Git credentials.** The error says the branch was not found, not that authentication failed: Git already accepted `ci-bot`. Changing secrets would also move the work away from the actual cause, the default `revision`.

**Silencing the registry error with TLS settings or a new registry.** The registry is meant to be plain HTTP inside the cluster. The client needs to be told (`--insecure`); adding auth or certificates changes nothing the check looks for.

**Binding `cluster-admin` or widening the Role to get past the Forbidden.** The Role was already enough; only the subject namespace was wrong. A broader grant passes the run and fails the final check that `deploy-sa` cannot read Secrets or touch `k8smissions`.

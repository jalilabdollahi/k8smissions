# Common Mistakes — Push Denied

## Mistake 1: Putting credentials in env vars

**Wrong approach:** Setting DOCKER_PASSWORD as an env var in the Task — exposed in pod spec and logs

**Correct approach:** Use Kubernetes Secrets attached to ServiceAccount

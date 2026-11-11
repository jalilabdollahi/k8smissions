1. The Application has `automated.selfHeal: true`, and the ConfigMap's `UPSTREAM_TIMEOUT_MS: "200"` comes from `deploy/configmap.yaml` in Git. A manual edit is drift, so Argo reverts it.
2. The upstream takes about 600 ms (`curl -w '%{time_total}'` from the probe), so 200 ms always times out.
3. Clone the `payments-api` repository, change the value (for example to `1500`) in `deploy/configmap.yaml`, commit and push to `main`.
4. Hard refresh the Application. Argo applies the new commit, the value sticks, `/ping` succeeds and self-heal stays on.

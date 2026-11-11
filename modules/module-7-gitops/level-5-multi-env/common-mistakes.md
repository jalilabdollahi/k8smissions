**Changing only `source.path`.** The Deployment gets the prod overlay's limits and log level, but the inline `kustomize.replicas` override still forces 1 replica. The Application is green again and production still runs one pod. Read the whole `spec.source`.

**Editing the live Deployment.** `kubectl scale` or `kubectl set env` on `shop` in `shop-prod` is reverted or shows the Application `OutOfSync`, and it leaves the Application definition wrong. The fix belongs in the Application.

**Pointing both Applications at `overlays/prod`.** That also changes the dev environment, which the check requires to stay at 1 replica and debug logging. Fix only the production Application.

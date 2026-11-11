**Cause.** The Deployment has only a liveness probe (`/live`, every 10s, `failureThreshold: 10`), so a wedged pod is restarted after about 100 seconds, and there is no readiness probe, so for those 100 seconds the pod stays in the Service endpoints and takes a quarter of the traffic, which hangs.

**Fix.** Add readiness (removes the pod from the endpoints within a couple of seconds) and shorten liveness (restarts it soon after), but not to a single failure: the app's `/live` is slow about one time in eight, so `failureThreshold: 1` restarts healthy pods.

    kubectl patch deployment ledger-api -n k8smissions --type=json -p '[
      {"op":"add","path":"/spec/template/spec/containers/0/readinessProbe","value":{"httpGet":{"path":"/ready","port":8080},"periodSeconds":1,"timeoutSeconds":1,"failureThreshold":2}},
      {"op":"replace","path":"/spec/template/spec/containers/0/livenessProbe","value":{"httpGet":{"path":"/live","port":8080},"periodSeconds":5,"timeoutSeconds":1,"failureThreshold":3}}]'

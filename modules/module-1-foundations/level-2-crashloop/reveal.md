1. `kubectl logs <pod> -c edge` shows `bind() to 0.0.0.0:80 failed (98: Address in use)`; `-c app` is healthy and listening.
2. The `app` container serves on port 80 and so does nginx. All containers in a pod share one network namespace, so only one can have port 80.
3. nginx already proxies to `127.0.0.1:8080`, so change the app's start command to `python -m http.server 8080`.
4. Edit the Deployment; the rollout replaces the pods with fresh ones that start without back-off.

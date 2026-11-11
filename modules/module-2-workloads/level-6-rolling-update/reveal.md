1. `kubectl -n k8smissions get deployment critical-api -o jsonpath='{.spec.strategy}'` prints `{"type":"Recreate"}`: on every release all four pods are terminated first, then four new pods start, hence about 25 seconds with no backend.
2. `kubectl -n k8smissions patch deployment critical-api -p '{"spec":{"strategy":{"type":"RollingUpdate"}}}'` restores the default behaviour (25% surge, 25% unavailable), so at least three pods always serve.
3. Check with a release: `kubectl -n k8smissions set env deployment/critical-api RELEASE=2` and `rollout status`.

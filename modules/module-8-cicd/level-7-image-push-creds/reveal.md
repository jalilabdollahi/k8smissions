The Secret has the right type, but its content is wrong twice: the `auths` key is `registry:5000` while the step pushes to `registry.k8smissions.svc.cluster.local:5000`, so the client finds no credentials and pushes anonymously, and the `auth` value was encoded with `echo`, so the password ends in a newline.

1. `kubectl logs <pod> -c step-push` shows `UNAUTHORIZED` for host `registry.k8smissions.svc.cluster.local:5000`.
2. Decode the Secret and its `auth`: key `registry:5000`, value `ci-push:ship-it-4711` plus a newline.
3. `kubectl create secret docker-registry registry-creds --docker-server=registry.k8smissions.svc.cluster.local:5000 --docker-username=ci-push --docker-password=ship-it-4711 --dry-run=client -o yaml | kubectl apply -f -`
4. Start a new run as ServiceAccount `builder`; the tag appears in the registry and `digest` matches.

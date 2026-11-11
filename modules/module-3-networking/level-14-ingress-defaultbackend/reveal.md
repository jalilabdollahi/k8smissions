1. `kubectl get ingressclass` lists only `nginx`; the Ingress asks for `nginx-internal`, which no controller owns, so ingress-nginx ignores it and answers everything with its built-in 404:

   `kubectl -n k8smissions patch ingress docs --type=merge -p '{"spec":{"ingressClassName":"nginx"}}'`

2. `Host: docs.k8sm.local` now returns the handbook. A `defaultBackend` added to `docs` itself does not catch unknown hosts, because that Ingress has rules. Put the fallback in its own Ingress with no rules:

   `kubectl -n k8smissions create ingress fallback --class=nginx --default-backend=maintenance:80`

   (A rule without a `host` that sends `/` to `maintenance` also works.)

3. Any other host now returns the maintenance page.

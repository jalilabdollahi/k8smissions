## What was broken

Ingress `docs` named `ingressClassName: nginx-internal`. Only the class `nginx` exists, so the ingress-nginx controller never picked the Ingress up and treated every request as unmatched, returning its default 404. Fixing the class makes the handbook reachable, but that alone leaves the second requirement open: unknown hostnames still get nginx's bare 404.

## The evidence

`kubectl describe ingress docs` showed no controller events (a class nobody owns produces silence, not errors). `kubectl get ingressclass` showed `nginx` only. The page itself, a plain nginx 404 with no app styling, said the request never reached a backend.

## Why Kubernetes behaves this way

An Ingress is only configuration; the class decides which controller implements it. Several controllers can coexist, each ignoring classes that are not theirs, so a typo disables the object quietly. Requests for a host no Ingress names are answered by the controller's catch-all server. ingress-nginx takes that server's backend from an Ingress that has only a `spec.defaultBackend` and no rules, or from a rule with no `host`. A `defaultBackend` on an Ingress that already has rules did not catch unknown hosts when this level was tested.

## The fix

Use an existing class on `docs`, and add a separate rule-less Ingress whose `defaultBackend` points at the `maintenance` Service (or a host-less rule to the same Service).

## In production

Run a deliberate default backend (a branded 404 or maintenance page) so unknown hosts do not leak the controller. Mark one IngressClass as the cluster default so an omitted class still works, and alert on Ingresses whose class matches no controller.

## Commands worth remembering

- `kubectl get ingressclass`
- `kubectl describe ingress <name>`
- `kubectl logs -n ingress-nginx deploy/ingress-nginx-controller`
- `kubectl explain ingress.spec.defaultBackend`

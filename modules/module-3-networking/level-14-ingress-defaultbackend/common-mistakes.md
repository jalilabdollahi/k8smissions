## Stopping once the handbook works

The first symptom is gone after the class change, but the platform team's second requirement is not met: an unknown host still gets nginx's default 404. The validator tests both.

## Adding `defaultBackend` to the `docs` Ingress

The field is accepted and the object looks right, but unknown hosts still get nginx's 404: with rules present, ingress-nginx does not use it as the catch-all. Test with a made-up Host header; put the fallback in its own Ingress or use a host-less rule.

## Creating an IngressClass called `nginx-internal`

A new IngressClass object only names a controller string; no controller has that string, so it changes nothing. Use the class that the running controller owns.

## Adding a catch-all host to the controller's ConfigMap or editing the controller

Anything inside the `ingress-nginx` namespace belongs to the platform. The default for your own hosts is configured on your Ingress, with `defaultBackend`.

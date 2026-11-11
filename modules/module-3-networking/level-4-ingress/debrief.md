## What was broken

Ingress `shop` mapped the public path `/shop` to the `storefront` Service and passed the path through untouched. The backend only knows `/` and `/items`, so `/shop/items` reached it unchanged and hit its own 404.

## The evidence

The 404 body ("backend: no such path") came from the application, not from nginx's own error page, so routing worked. The controller log showed the request being proxied to the backend as `/shop/items`. Even `/shop` alone failed, because the backend received `/shop`, not `/`.

## Why Kubernetes behaves this way

An Ingress only decides which Service receives a request; it says nothing about rewriting. A `Prefix` path matches but doesn't remove the prefix. ingress-nginx implements rewriting through an annotation, and the new path is built from regular-expression capture groups in the Ingress path. Capture groups need `pathType: ImplementationSpecific`.

## The fix

`rewrite-target: /$2` together with path `/shop(/|$)(.*)`. Changing the path to `/` would make `/shop/items` work only by taking over every route on the host and breaking the other prefixes.

## In production

The controller's rewrite behaviour is not portable to other Ingress controllers, so keep backends able to serve under a configurable base path where you can. Test both the bare prefix and a nested path after every change.

## Commands worth remembering

- `kubectl -n ingress-nginx logs deploy/ingress-nginx-controller`
- `kubectl describe ingress <name>`
- `kubectl exec probe -- curl -H 'Host: <host>' http://ingress-nginx-controller.ingress-nginx.svc/<path>`

ingress-nginx forwards the request path unchanged, so the backend receives `/shop/items`, which it has never served. The prefix has to be stripped before the request is proxied.

1. `kubectl -n ingress-nginx logs deploy/ingress-nginx-controller` shows the upstream request path `/shop/items`.
2. Edit Ingress `shop`: add the annotation `nginx.ingress.kubernetes.io/rewrite-target: /$2`.
3. Change the path to `/shop(/|$)(.*)` with `pathType: ImplementationSpecific`, so group 2 holds what follows `/shop` and `/shop` alone maps to `/`.

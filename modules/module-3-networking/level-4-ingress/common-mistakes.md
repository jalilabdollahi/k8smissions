## Changing the path to /

The Ingress then matches every URL on the host, so `/shop/items` is no longer routed the way the other prefixes expect and the shop is no longer under `/shop`. The prefix has to be removed on its way to the backend, not dropped from the public URL.

## Using only the rewrite annotation with a Prefix path

`rewrite-target: /` with `path: /shop` sends everything to `/`, so `/shop/items` returns the home page. The capture group `$2` is what carries the rest of the path, and capture groups need a regular-expression path.

## Editing the backend's Service

The Service has endpoints and the backend answers. The problem is the path the Ingress forwards, which is configured on the Ingress.

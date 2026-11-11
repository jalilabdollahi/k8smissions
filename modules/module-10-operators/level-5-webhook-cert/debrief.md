## What was broken

An admission webhook is an HTTPS call from the API server to your service, and it only works if the TLS handshake succeeds. Here it failed twice in a row, for two unrelated reasons: the `caBundle` in the webhook configuration did not match the issuer of the server's certificate, and once that was fixed, the certificate itself turned out to be expired.

## The evidence

Creating a guarded pod printed the handshake error, with the cause in plain words each time: first `certificate signed by unknown authority` (the client's trust is wrong), then `certificate has expired or is not yet valid` (the server's certificate is wrong). `openssl x509 -noout -dates -issuer` on the PEM from the Secret confirms both without guessing.

## Why Kubernetes behaved this way

The API server verifies the webhook's certificate against `caBundle` and the service's DNS name; it does not skip verification and it does not fall back. With `failurePolicy: Fail` an unreachable or untrusted webhook rejects the request, which is what you want from a security guard and is also why a stale certificate stops every guarded pod. The server loads its certificate once at start, so renewing the Secret is not enough: the process has to restart (or reload) to use it.

## In production

Do not click through the failure by deleting the webhook or setting `Ignore`: that silently turns the policy off, which the validator's `nginx:latest` probe catches. Use cert-manager with the CA injector so `caBundle` and the serving certificate rotate together, scope webhooks with `namespaceSelector` and `objectSelector` so a failed guard cannot take down the control plane, and alert on certificate expiry.

## Worth remembering

- `kubectl get validatingwebhookconfiguration <name> -o jsonpath='{.webhooks[*].clientConfig}'`
- `kubectl get secret <name> -o jsonpath='{.data.tls\.crt}' | base64 -d | openssl x509 -noout -dates -issuer`
- `kubectl run ... --dry-run=server` calls webhooks without creating anything

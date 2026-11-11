**What was broken.** Three separate things made the namespace slow and unreliable. The webhook's Service was a selectorless Service with hand-written Endpoints pointing at an address that no longer exists; the webhook's `caBundle` trusted the wrong CA; and `inventory-sync` polled the API server every 10 ms.

**The evidence.** `kubectl create configmap` took ten seconds and ended with `failed calling webhook ... context deadline exceeded`, which is the webhook timeout. `get svc,endpoints config-guard` shows a Service with no selector and an Endpoints entry on `192.0.2.10`. After that was fixed the message changed to `x509: certificate signed by unknown authority`, the sign of a bad `caBundle`. The syncer's own log and `/` endpoint show its interval and request rate.

**Why Kubernetes behaved this way.** The API server calls validating webhooks synchronously during admission, so their latency is added to every matching request. With `failurePolicy: Fail`, a webhook that cannot be reached blocks the write after `timeoutSeconds`. A Service without a selector never gets endpoints from the endpoints controller, so an old manual Endpoints object stays forever. The API server verifies the webhook's server certificate with `caBundle`, not with the cluster CA.

**The fix.** Give the Service a selector and let the controller manage endpoints, patch `caBundle` with the CA that really signed the certificate, and slow the poller. Keep the webhook: lowering `timeoutSeconds` or switching to `Ignore` would hide the symptom and drop the policy it enforces.

**In production.** Scope webhooks narrowly (`namespaceSelector`, `objectSelector`, `rules`), keep timeouts short (1 to 3 seconds), run more than one backend replica, and manage `caBundle` with cert-manager's CA injector. Watch `apiserver_admission_webhook_request_total` and `apiserver_request_duration_seconds`.

**Commands to remember.** `kubectl get validatingwebhookconfigurations -o yaml`, `kubectl get endpointslices -l kubernetes.io/service-name=<svc>`, `kubectl create --v=6 ...` for request timing.

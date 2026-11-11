1. **Dead backend address.** The `config-guard` Service has no selector and a hand-written Endpoints object pointing at `192.0.2.10`, an address nobody answers on, so every ConfigMap create waits for the 10 s webhook timeout and then fails (`failurePolicy: Fail`). Add `selector: app=config-guard` to the Service and delete the stale Endpoints.
2. **Wrong caBundle.** Once the backend is reachable, creates fail fast with `x509: certificate signed by unknown authority`: the webhook's `caBundle` is another CA's certificate. The right one is key `ca.crt` of Secret `config-guard-tls`; patch the webhook with that base64.
3. **A noisy client.** `inventory-sync` polls every 10 ms (about 200 API requests a second). `kubectl set env deploy/inventory-sync POLL_INTERVAL_MS=30000`.

Deleting the webhook makes creates fast but removes the policy: the validator creates a ConfigMap labelled `unreviewed=true` and expects `config-guard`'s refusal.

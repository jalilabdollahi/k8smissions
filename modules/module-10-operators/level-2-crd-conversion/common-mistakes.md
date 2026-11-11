## Wiring the strategy but not the CA

Setting `strategy: Webhook` with a service reference and no `caBundle` (or the wrong one) makes every `kubectl get cache` fail with an `x509: certificate signed by unknown authority` error, which is worse than the blank field you started with. The CA that signed the converter is in `converter-ca`; copy it as it is, it is already base64.

## Forgetting the path

The service reference without `path` makes the API server call `/` and the converter answers 404 (see its logs). The converter serves `/convert`.

## Fixing the symptom in the controller

Making `cache-controller` read `maxMemoryMB` appears to work for the old objects but breaks for every cache created through `v1`, and the next client of the `v1` API gets blank data again. The validator reads objects through both versions to catch this.

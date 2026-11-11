The CRD has two versions but `spec.conversion.strategy: None`, so `v1alpha1` objects are only relabelled `v1` and `maxMemoryMB` is pruned away. The working converter `cache-converter` just needs to be wired in:

```bash
CA=$(kubectl -n k8smissions get secret converter-ca -o jsonpath='{.data.ca\.crt}')
kubectl patch crd caches.cache.acme.io --type=merge -p "{\"spec\":{\"conversion\":{\"strategy\":\"Webhook\",\"webhook\":{\"conversionReviewVersions\":[\"v1\"],\"clientConfig\":{\"caBundle\":\"$CA\",\"service\":{\"namespace\":\"k8smissions\",\"name\":\"cache-converter\",\"path\":\"/convert\",\"port\":443}}}}}}"
```

- `strategy: Webhook` turns conversion on.
- `service` plus `path: /convert` is where the API server posts a ConversionReview (the server only has a `/convert` route).
- `caBundle` is the CA that signed the converter's certificate; the Secret already holds it base64-encoded.
- `conversionReviewVersions: ["v1"]` lists the review versions the API server may use.

`cache-controller` re-reads the caches every few seconds, so its ConfigMaps (`cache-sessions` and the others) correct themselves.

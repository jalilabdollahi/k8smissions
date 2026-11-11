kubectl -n k8smissions get secret converter-ca -o jsonpath='{.data.ca\.crt}' | head -c 30; echo
CA=$(kubectl -n k8smissions get secret converter-ca -o jsonpath='{.data.ca\.crt}')
kubectl patch crd caches.cache.acme.io --type=merge -p "{\"spec\":{\"conversion\":{\"strategy\":\"Webhook\",\"webhook\":{\"conversionReviewVersions\":[\"v1\"],\"clientConfig\":{\"caBundle\":\"$CA\",\"service\":{\"namespace\":\"k8smissions\",\"name\":\"cache-converter\",\"path\":\"/convert\",\"port\":443}}}}}}"
kubectl -n k8smissions get cache.v1.cache.acme.io sessions -o jsonpath='{.spec.memory}{"\n"}'

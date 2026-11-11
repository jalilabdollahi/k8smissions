**Three independent faults.**

1. **DNS search expansion.** `storefront` looks up `pricing.catalog.internal` (2 dots) with `ndots: 5` and three search domains, so each page costs 4 queries, 3 of which end in NXDOMAIN. Make the name fully qualified (trailing dot) or lower `ndots`:

       kubectl set env deployment/storefront -n k8smissions PRICING_HOST=pricing.catalog.internal.

2. **CPU limit on pricing.** A page costs about 20ms of CPU and the container is limited to 100m, so it is throttled most of the time. Raise the limit (or remove it) and keep a request:

       kubectl set resources deployment/pricing -n k8smissions --requests=cpu=100m --limits=cpu=1

3. **sessionAffinity: ClientIP on the pricing Service.** There is one storefront pod, so one client IP, and all requests stick to the same pricing pod; the other two idle. Remove the affinity:

       kubectl patch service pricing -n k8smissions -p '{"spec":{"sessionAffinity":"None"}}'

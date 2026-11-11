1. `nslookup quorum` from the probe pod returns nothing: the headless Service only publishes records for Ready pods, and no pod is Ready.
2. The readiness probe needs two peers from that same DNS name, so it can never pass: a deadlock.
3. Tell the Service to publish addresses of pods that are not Ready yet:

   `kubectl -n k8smissions patch svc quorum -p '{"spec":{"publishNotReadyAddresses":true}}'`

4. Within a few seconds DNS returns the three pod IPs, the probes pass, and `quorum` becomes 3/3 Ready.

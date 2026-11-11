The `reporter` pod template sets `dnsPolicy: None` with a single nameserver, 8.8.8.8, so the pods never talk to cluster DNS and can't resolve Service names.

1. `kubectl -n k8smissions exec deploy/reporter -- cat /etc/resolv.conf` shows only `nameserver 8.8.8.8` and no `svc.cluster.local` search domains.
2. Patch the Deployment: `kubectl -n k8smissions patch deployment reporter --type=json -p '[{"op":"remove","path":"/spec/template/spec/dnsConfig"},{"op":"replace","path":"/spec/template/spec/dnsPolicy","value":"ClusterFirst"}]'`.
3. Wait for the rollout; the new pods get the cluster resolver and search list.

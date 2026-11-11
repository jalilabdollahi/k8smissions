**Fault 1: the gateways bypass the cache.** `session-gw` has `dnsConfig.nameservers: [10.96.150.110]`, which is the ClusterIP of `dns-upstream`. Point it at the ClusterIP of the `dns-cache` Service (`10.96.150.111`, `internalTrafficPolicy: Local`, so every pod reaches the cache on its own node):

    kubectl patch deployment session-gw -n k8smissions --type=json \
      -p '[{"op":"replace","path":"/spec/template/spec/dnsConfig/nameservers/0","value":"10.96.150.111"}]'

**Fault 2: the cache forgets after one second.** The cache block is `success 9984 1`: the second number is a maximum TTL in seconds. Raise it (300 is plenty here, the upstream hands out 300s answers) in the ConfigMap `dns-cache-corefile`:

    cache {
        success 9984 300
    }

**Restart the cache.** CoreDNS reads its Corefile at start, so the edited ConfigMap changes nothing until `kubectl rollout restart daemonset/dns-cache`.

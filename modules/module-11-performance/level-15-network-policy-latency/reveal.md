**Cause.** `sku-history.catalog.internal` has 60 A records, more than fit in a 512 byte UDP reply. CoreDNS answers over UDP with the truncated flag set, and the musl resolver in the pod retries the query over TCP port 53. The egress policy `price-feed-egress` only allows **UDP** 53 to the resolver, so the TCP connection attempt is dropped silently; the client waits its 5 second timeout and the lookup fails. Small names fit in one UDP packet and are never affected.

**Fix.** Allow TCP 53 to the same resolver in the same rule:

    kubectl patch networkpolicy price-feed-egress -n k8smissions --type=json \
      -p '[{"op":"add","path":"/spec/egress/0/ports/-","value":{"protocol":"TCP","port":53}}]'

Opening all egress would fix the lookup but break the requirement that ledger-sink stays unreachable.

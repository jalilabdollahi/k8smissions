**Fixing only the nameserver.** The cache log fills up and it feels solved, but with a one-second TTL cap about a third of the lookups still miss and go upstream, so p95 stays around 85ms and the upstream ratio stays far above 10%. Read the upstream log after the change.

**Editing the Corefile ConfigMap and stopping there.** CoreDNS does not watch its file. Until the DaemonSet is restarted the cache pods keep the old cap and nothing changes.

**Bypassing the problem on the upstream.** Removing the `erratic` delay from `dns-upstream` makes lookups fast, but the upstream stands in for a real, slow resolver. The validator asks it directly and expects it to stay slow; the cache is the fix, not a faster upstream.

`quotas.payments.internal` has two dots and the pod's resolv.conf says `ndots:5`, so the resolver treats it as relative and tries `.k8smissions.svc.cluster.local`, `.svc.cluster.local` and `.cluster.local` first (three NXDOMAIN answers) before asking for the real name: 4 queries per lookup.

1. `kubectl logs deploy/dns-lab` shows the four queries for each lookup; `kubectl exec deploy/rate-limiter -- cat /etc/resolv.conf` shows `ndots:5` and the three search domains.
2. Lower `ndots` to 2 (`kubectl patch deployment rate-limiter --type=json -p '[{"op":"replace","path":"/spec/template/spec/dnsConfig/options/0/value","value":"2"}]'`), or set `QUOTAS_HOST=quotas.payments.internal.` with a trailing dot.
3. Do not empty the search list: `session-cache` is a short name and needs it.

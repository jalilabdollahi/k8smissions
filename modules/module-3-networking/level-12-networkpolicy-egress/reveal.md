1. `default-deny-egress` blocks everything `invoice` sends, including DNS queries to CoreDNS, so `ledger-db` does not resolve. Allow DNS to the CoreDNS pods by label, not by IP:

   `kubectl -n payments apply -f -` with a NetworkPolicy `allow-dns` selecting `app=invoice`, egress `to` a `namespaceSelector` (`kubernetes.io/metadata.name: kube-system`) and `podSelector` (`k8s-app: kube-dns`), ports 53 UDP and TCP.

2. Once names resolve, the call still times out: `allow-db` permits peers labelled `role=db`, but the database pods carry `app=ledger-db`:

   `kubectl -n payments patch networkpolicy allow-db --type=json -p '[{"op":"replace","path":"/spec/egress/0/to/0/podSelector/matchLabels","value":{"app":"ledger-db"}}]'`

3. `audit-log` has no rule, so it stays blocked.

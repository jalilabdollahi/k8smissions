## Opening port 53 to everyone

An egress rule with only `ports: [{port: 53}]` and no `to` allows port 53 to any destination, which is wider than needed. Name the CoreDNS pods with `namespaceSelector` and `podSelector` in the same `to` entry.

## Allowing UDP 53 only

DNS falls back to TCP for large answers. Allow both protocols, or occasional lookups fail in ways that are hard to reproduce.

## Deleting the egress policies

Everything works, but `invoice` can now call `audit-log` and anything else. The point of the lockdown stays: fix the rules, do not remove them.

## Fixing DNS and stopping there

The name resolves, but the call to `ledger-db` still times out until the peer label in `allow-db` is right.

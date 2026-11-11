**Allowing all egress.** Deleting the policy or adding `- {}` as an egress rule makes the lookup fast, and it also lets price-feed reach everything, including `ledger-sink`. The validator checks that the sink stays unreachable.

**Raising the application's timeout or retries.** Lookups now wait longer for a TCP connection that can never complete, and still fail. The 5 second delay is the symptom, not the cause.

**Blaming the DNS server or its Service.** Small names resolve, the Service has endpoints and the resolver log shows the UDP queries arriving. The problem only exists for the answer that does not fit in one UDP packet, which is a clue about the protocol, not the server's health.

# Common Mistakes — Handshake Refused

## Mistake 1: Disabling webhook TLS verification

**Wrong approach:** Setting insecureSkipTLSVerify: true in clientConfig — massive security hole

**Correct approach:** Always fix TLS properly; use cert-manager for automated certificate management
